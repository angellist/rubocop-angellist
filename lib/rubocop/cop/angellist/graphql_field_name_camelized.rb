# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Ensures GraphQL field names use camelCase rather than snake_case.
      # graphql-ruby auto-camelizes snake_case field names by default, but
      # relying on implicit camelization makes the code harder to grep and
      # can hide bugs when `method:` or `resolver_method:` is also involved.
      #
      # Fields with `camelize: false` are exempt since they intentionally
      # preserve their exact casing.
      #
      # @example
      #   # bad — snake_case field name
      #   field :post_money_valuation, Types::MoneyType, null: true
      #   field :created_at, Types::DateTimeType, method: :created_at, null: true
      #
      #   # good — camelCase field name
      #   field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      #   field :createdAt, Types::DateTimeType, method: :created_at, null: true
      #
      #   # good — single-word field (no underscores)
      #   field :id, ID, method: :id, null: false
      #   field :email, String, method: :email, null: true
      #
      #   # good — camelize: false explicitly opts out
      #   field :only_needs_kyc, Boolean, camelize: false, null: true
      #
      class GraphqlFieldNameCamelized < Base
        MSG = 'GraphQL field `:%<field_name>s` uses snake_case. Use camelCase instead ' \
              '(e.g., `:%<camelized_name>s`) with an explicit `method:` or `resolver_method:` option.'

        RESTRICT_ON_SEND = [:field].freeze

        # @!method field_name(node)
        def_node_matcher :field_name, <<~PATTERN
          (send nil? :field (sym $_) ...)
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

          name_str = name.to_s

          # Only flag fields with underscores (snake_case)
          return if !name_str.include?('_')

          # Skip if camelize: false
          return if has_camelize_false?(node)

          camelized = camelize(name_str)
          message = format(MSG, field_name: name, camelized_name: camelized)
          add_offense(node, message: message)
        end

        private

        def camelize(str)
          parts = str.split('_')
          parts[0] + parts[1..].map(&:capitalize).join
        end
      end
    end
  end
end
