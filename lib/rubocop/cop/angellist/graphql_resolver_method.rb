# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Detects GraphQL fields that use `method:` when a custom resolver method
      # with the same name is defined in the type class. In graphql-ruby,
      # `method:` calls the method on the underlying data object (`object`),
      # while `resolver_method:` calls it on the type class instance (`self`).
      # Using `method:` when a custom `def` exists in the type class will
      # silently bypass that resolver.
      #
      # @example
      #   # bad — post_money_valuation is defined as a def in this class,
      #   #        but method: will call object.post_money_valuation instead
      #   class Types::MyType < Types::BaseObject
      #     field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      #
      #     def post_money_valuation
      #       object&.valuation&.to_money
      #     end
      #   end
      #
      #   # good — resolver_method: calls self.post_money_valuation on the type class
      #   class Types::MyType < Types::BaseObject
      #     field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true
      #
      #     def post_money_valuation
      #       object&.valuation&.to_money
      #     end
      #   end
      #
      #   # good — no custom def exists, so method: correctly delegates to the data object
      #   class Types::MyType < Types::BaseObject
      #     field :closedAt, Types::DateTimeType, method: :closed_at, null: true
      #   end
      #
      class GraphqlResolverMethod < Base
        extend AutoCorrector

        MSG = '`method: :%<method_name>s` will call `object.%<method_name>s` (the data object), ' \
              'but this class defines `def %<method_name>s` which is a resolver on the type class. ' \
              'Use `resolver_method: :%<method_name>s` instead so the custom resolver is called.'

        RESTRICT_ON_SEND = [:field].freeze

        # @!method field_with_method_option(node)
        def_node_matcher :field_with_method_option, <<~PATTERN
          {
            (send nil? :field _ _* (hash <(pair (sym :method) (sym $_)) ...>))
            (send nil? :field _ (hash <(pair (sym :method) (sym $_)) ...>))
          }
        PATTERN

        def on_send(node)
          field_with_method_option(node) do |method_name|
            # Find the enclosing class or module
            enclosing_class = node.each_ancestor(:class, :module).first
            return if !enclosing_class

            # Check if this class defines a method with the same name
            if class_defines_method?(enclosing_class, method_name)
              message = format(MSG, method_name: method_name)
              method_pair = find_method_pair(node)
              add_offense(method_pair || node, message: message) do |corrector|
                if method_pair
                  corrector.replace(
                    method_pair.key.loc.expression,
                    'resolver_method',
                  )
                end
              end
            end
          end
        end

        private

        def class_defines_method?(class_node, method_name)
          class_node.body&.each_descendant(:def)&.any? do |def_node|
            def_node.method_name == method_name
          end
        end

        def find_method_pair(field_node)
          field_node.arguments.each do |arg|
            next if !arg.hash_type?

            arg.pairs.each do |pair|
              return pair if pair.key.sym_type? && pair.key.value == :method
            end
          end
          nil
        end
      end
    end
  end
end
