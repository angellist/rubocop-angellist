# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Enforces that `Timecop.freeze` and `Timecop.travel` are always called
      # with a block. Calling these methods without a block requires a manual
      # `Timecop.return` to reset the time, which is easy to forget and leads
      # to flaky specs.
      #
      # @example
      #   # bad
      #   Timecop.freeze(Time.now)
      #   Timecop.travel(1.day.from_now)
      #
      #   # bad - even with Timecop.return, the block form is preferred
      #   Timecop.freeze(Time.now)
      #   do_something
      #   Timecop.return
      #
      #   # good
      #   Timecop.freeze(Time.now) do
      #     do_something
      #   end
      #
      #   # good
      #   Timecop.travel(1.day.from_now) do
      #     do_something
      #   end
      #
      class TimecopWithoutBlock < ::RuboCop::Cop::Base
        MSG = 'Use the block form of `%<method>s` instead of calling it without a block.'

        RESTRICT_ON_SEND = [:freeze, :travel].freeze

        # @!method timecop_call?(node)
        def_node_matcher :timecop_call?, <<~PATTERN
          (send (const {nil? (cbase)} :Timecop) {:freeze :travel} ...)
        PATTERN

        sig { params(node: RuboCop::AST::Node).void }
        def on_send(node)
          return if !timecop_call?(node)
          return if node.block_literal?

          add_offense(node, message: format(MSG, method: "Timecop.#{node.method_name}"))
        end
      end
    end
  end
end
