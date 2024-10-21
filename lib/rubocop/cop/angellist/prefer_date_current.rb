# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Prefer Date.current over Time.zone.today. It's less verbose, and slightly more semantically meaningful.
      #
      # @example:
      #   # bad
      #   Time.zone.today
      #
      #   # good
      #   Date.current
      #
      class PreferDateCurrent < ::RuboCop::Cop::Base
        extend T::Sig
        extend AutoCorrector

        MSG = 'Use `Date.current` instead of `Time.zone.today`.'

        # Don't call `on_send` unless the method name is in this list
        RESTRICT_ON_SEND = [:today].freeze

        # @!method today?(node)
        def_node_matcher :time_zone_today?, <<~PATTERN
          (send (send (:const {nil? (cbase)} :Time) :zone) :today ...)
        PATTERN

        sig { params(node: RuboCop::AST::Node).void }
        def on_send(node)
          return if !time_zone_today?(node)

          add_offense(node, message: MSG) do |corrector|
            autocorrect(corrector, node)
          end
        end

        private

        sig { params(corrector: RuboCop::Cop::Corrector, node: RuboCop::AST::Node).void }
        def autocorrect(corrector, node)
          corrector.replace(node, 'Date.current')
        end
      end
    end
  end
end
