# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Requires all GraphQL fields with snake_case names to have an explicit
      # `method:` or `resolver_method:` option. This makes the mapping between
      # the camelCase GraphQL field name and the snake_case Ruby method explicit,
      # improving readability and preventing subtle bugs.
      #
      # Fields that are already camelCase or single-word (no underscores) are
      # not flagged, since they don't need the mapping.
      #
      # Fields with `camelize: false` are also not flagged, since they
      # intentionally preserve their exact casing.
      #
      # @example
      #   # bad — implicit mapping from snake_case to camelCase
      #   field :post_money_valuation, Types::MoneyType, null: true
      #
      #   # good — explicit method: mapping
      #   field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      #
      #   # good — explicit resolver_method: mapping (when type class defines a custom def)
      #   field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true
      #
      #   # good — single-word field, no mapping needed
      #   field :id, ID, null: false
      #
      #   # good — already has method: option
      #   field :avatarUrl, String, method: :avatar, null: true
      #
      class GraphqlExplicitMethod < Base
        MSG = 'GraphQL field `:%<field_name>s` contains underscores but has no explicit `method:` or ' \
              '`resolver_method:` option. Add `method: :%<field_name>s` (if delegating to the data object) ' \
              'or `resolver_method: :%<field_name>s` (if a custom def exists in this class) and rename ' \
              'the field symbol to camelCase.'

        RESTRICT_ON_SEND = [:field].freeze

        # @!method field_name(node)
        def_node_matcher :field_name, <<~PATTERN
          (send nil? :field (sym $_) ...)
        PATTERN

        # @!method has_method_option?(node)
        def_node_matcher :has_method_option?, <<~PATTERN
          (send nil? :field _ _+ (hash <(pair (sym {:method :resolver_method}) _) ...>))
        PATTERN

        # @!method has_camelize_false?(node)
        def_node_matcher :has_camelize_false?, <<~PATTERN
          (send nil? :field _ _+ (hash <(pair (sym :camelize) (false)) ...>))
        PATTERN

        def on_send(node)
          name = field_name(node)
          return if !name

          # Only flag fields with underscores (snake_case)
          return if !name.to_s.include?('_')

          # Skip if already has method: or resolver_method:
          return if has_method_option?(node)

          # Skip if camelize: false
          return if has_camelize_false?(node)

          message = format(MSG, field_name: name)
          add_offense(node, message: message)
        end
      end
    end
  end
end
