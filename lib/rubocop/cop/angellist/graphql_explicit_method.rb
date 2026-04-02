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
        extend AutoCorrector

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

        # @!method has_resolver_or_mutation?(node)
        def_node_matcher :has_resolver_or_mutation?, <<~PATTERN
          {
            (send nil? :field _ _* (hash <(pair (sym {:resolver :mutation}) _) ...>))
            (send nil? :field _ (hash <(pair (sym {:resolver :mutation}) _) ...>))
          }
        PATTERN

        def on_send(node)
          name = field_name(node)
          return if !name

          # Skip if already has method: or resolver_method:
          return if has_method_option?(node)

          # Skip if camelize: false
          return if has_camelize_false?(node)

          # Skip if field uses resolver: or mutation: (delegates resolution entirely)
          return if has_resolver_or_mutation?(node)

          name_str = name.to_s
          message = format(MSG, field_name: name)
          add_offense(node, message: message) do |corrector|
            # Determine the method name to use
            method_name = underscore(name_str)
            option_key = resolver_method_needed?(node, method_name) ? 'resolver_method' : 'method'
            insert_method_option(corrector, node, option_key, method_name)
          end
        end

        private

        def resolver_method_needed?(node, method_name)
          enclosing_class = node.each_ancestor(:class, :module).first
          return false if !enclosing_class

          method_sym = method_name.to_sym
          enclosing_class.body&.each_descendant(:def)&.any? do |def_node|
            def_node.method_name == method_sym
          end
        end

        def underscore(str)
          str.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        end

        def insert_method_option(corrector, node, option_key, method_name)
          hash_node = find_hash_arg(node)
          if hash_node
            first_pair = hash_node.pairs.first
            corrector.insert_before(first_pair, "#{option_key}: :#{method_name}, ")
          else
            # No hash arg exists; append after the last argument
            corrector.insert_after(node.last_argument, ", #{option_key}: :#{method_name}")
          end
        end

        def find_hash_arg(node)
          node.arguments.each do |arg|
            return arg if arg.hash_type?
          end
          nil
        end
      end
    end
  end
end
