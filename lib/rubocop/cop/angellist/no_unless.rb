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
      class NoUnless < Base
        extend AutoCorrector

        MSG = 'Use `if !condition` instead of `unless condition`.'

        def on_if(node)
          return if !node.unless?

          add_offense(node, message: MSG) do |corrector|
            corrector.replace(node.loc.keyword, 'if')
            autocorrect(corrector, node.condition)
          end
        end

        private

        def autocorrect(corrector, node)
          case node.type
          when :begin
            autocorrect(corrector, node.children.first)
          when :send
            autocorrect_send_node(corrector, node)
          when :or, :and
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

        def autocorrect_send_node(corrector, node)
          if node.method?(:!)
            corrector.remove(node.loc.selector)
          else
            corrector.replace(node.loc.expression, "!#{node.source}")
          end
        end
      end
    end
  end
end
