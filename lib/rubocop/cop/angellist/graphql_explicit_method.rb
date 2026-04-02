# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Requires all GraphQL fields to have an explicit `method:` or
      # `resolver_method:` option. This makes the mapping between the GraphQL
      # field name and the Ruby method explicit, improving readability and
      # preventing subtle bugs.
      #
      # Fields with `camelize: false` are not flagged, since they intentionally
      # preserve their exact casing.
      #
      # @example
      #   # bad — no explicit method mapping
      #   field :post_money_valuation, Types::MoneyType, null: true
      #   field :id, ID, null: false
      #
      #   # good — explicit method: mapping
      #   field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      #   field :id, ID, method: :id, null: false
      #
      #   # good — explicit resolver_method: mapping (when type class defines a custom def)
      #   field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true
      #   field :id, ID, resolver_method: :id, null: false
      #
      class GraphqlExplicitMethod < Base
        MSG = 'GraphQL field `:%<field_name>s` has no explicit `method:` or ' \
              '`resolver_method:` option. Add `method: :%<field_name>s` (if delegating to the data object) ' \
              'or `resolver_method: :%<field_name>s` (if a custom def exists in this class).'

        RESTRICT_ON_SEND = [:field].freeze

        # @!method field_name(node)
        def_node_matcher :field_name, <<~PATTERN
          (send nil? :field (sym $_) ...)
        PATTERN

        # @!method has_method_option?(node)
        def_node_matcher :has_method_option?, <<~PATTERN
          {
            (send nil? :field _ _* (hash <(pair (sym {:method :resolver_method}) _) ...>))
            (send nil? :field _ (hash <(pair (sym {:method :resolver_method}) _) ...>))
          }
        PATTERN

        # @!method has_camelize_false?(node)
        def_node_matcher :has_camelize_false?, <<~PATTERN
          {
            (send nil? :field _ _* (hash <(pair (sym :camelize) (false)) ...>))
            (send nil? :field _ (hash <(pair (sym :camelize) (false)) ...>))
          }
        PATTERN

        def on_send(node)
          name = field_name(node)
          return if !name

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
