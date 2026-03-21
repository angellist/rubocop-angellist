# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Checks for unnecessary `extend T::Sig` in classes and modules.
      #
      # `T::Sig` has been monkey-patched into `Module`, so `sig` is available
      # everywhere without needing to explicitly extend it.
      #
      # @example
      #   # bad
      #   class Foo
      #     extend T::Sig
      #
      #     sig { returns(String) }
      #     def bar
      #       'baz'
      #     end
      #   end
      #
      #   # bad
      #   module Foo
      #     extend T::Sig
      #   end
      #
      #   # bad
      #   class Foo
      #     class << self
      #       extend T::Sig
      #     end
      #   end
      #
      #   # good
      #   class Foo
      #     sig { returns(String) }
      #     def bar
      #       'baz'
      #     end
      #   end
      #
      class RedundantExtendTSig < ::RuboCop::Cop::Base
        include RangeHelp
        extend AutoCorrector

        MSG = 'Unnecessary `extend T::Sig`. `sig` is already available without it.'

        # @!method extend_t_sig?(node)
        # @!method extend_t_sig?(node)
        def_node_matcher :extend_t_sig?, <<~PATTERN
          (send nil? :extend (const (const {nil? (cbase)} :T) :Sig))
        PATTERN

        sig { params(node: RuboCop::AST::SendNode).void }
        def on_send(node)
          return if !extend_t_sig?(node)

          add_offense(node) do |corrector|
            range = range_by_whole_lines(node.source_range, include_final_newline: true)
            # Also remove a trailing blank line if present
            if range.source_buffer.source[range.end_pos] == "\n"
              range = range.adjust(end_pos: 1)
            end
            corrector.remove(range)
          end
        end
      end
    end
  end
end
