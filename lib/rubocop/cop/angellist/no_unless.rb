# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Checks for usages of unless and corrects them to if !(...) instead.
      #
      # @example
      #   # bad
      #   do_stuff unless condition
      #   unless condition && other_condition
      #     do_stuff
      #   end
      #
      #   # good
      #   do_stuff if !condition
      #   if !(condition && other_condition)
      #     do_stuff
      #   end
      #
      class NoUnless < ::RuboCop::Cop::Base
        extend T::Sig
        extend AutoCorrector

        MSG = 'Use `if !condition` instead of `unless condition`.'

        sig { params(node: RuboCop::AST::IfNode).void }
        def on_if(node)
          return if !node.unless?

          add_offense(node, message: MSG) do |corrector|
            corrector.replace(node.loc.keyword, 'if')
            autocorrect(corrector, node.condition)
          end
        end

        private

        sig { params(corrector: RuboCop::Cop::Corrector, node: RuboCop::AST::IfNode).void }
        def autocorrect(corrector, node)
          case node.type
          when :begin
            autocorrect(corrector, node.children.first)
          when :send
            node = T.cast(node, RuboCop::AST::SendNode)
            autocorrect_send_node(corrector, node)
          when :or, :and
            node = T.cast(node, T.any(RuboCop::AST::OrNode, RuboCop::AST::AndNode))
            corrector.replace(node.loc.operator, node.inverse_operator)
            autocorrect(corrector, node.lhs)
            autocorrect(corrector, node.rhs)
          when :true
            corrector.replace(node.loc.expression, 'false')
          when :false
            corrector.replace(node.loc.expression, 'true')
          else
            corrector.replace(node.loc.expression, "!#{node.source}")
          end
        end

        sig { params(corrector: RuboCop::Cop::Corrector, node: RuboCop::AST::SendNode).void }
        def autocorrect_send_node(corrector, node)
          if inverse_comparisons.key?(node.method_name)
            corrector.replace(node.loc.selector, inverse_comparisons[node.method_name].to_s)
          elsif node.method?(:!)
            corrector.remove(node.loc.selector)
          else
            corrector.replace(node.loc.expression, "!#{node.source}")
          end
        end

        sig { returns(T::Hash[Symbol, Symbol]) }
        def inverse_comparisons
          @inverse_comparisons ||= T.let(
            begin
              method_mappings = {
                :== => :!=,
                :> => :<=,
                :< => :>=,
              }
              method_mappings.merge(method_mappings.invert)
            end,
            T.nilable(T::Hash[Symbol, Symbol]),
          )
        end
      end
    end
  end
end
