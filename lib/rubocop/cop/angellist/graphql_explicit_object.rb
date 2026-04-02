# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Requires GraphQL type classes to explicitly declare their underlying
      # object type via `object_type(ClassName)`. This makes the relationship
      # between the GraphQL type and its data object clear and greppable.
      #
      # Classes whose name ends with `QueryType`, `MutationType`, or starts
      # with `Base` are exempt, as they typically don't wrap a single data object.
      #
      # @example
      #   # bad — no object_type declaration
      #   class Types::Admin::DealAccessLinkType < Types::Venture
      #     field :id, ID, null: false
      #   end
      #
      #   # good — explicit object_type
      #   class Types::Admin::DealAccessLinkType < Types::Venture
      #     object_type(DealAccessLink)
      #
      #     field :id, ID, null: false
      #   end
      #
      #   # good — QueryType is exempt
      #   class QueryType < Types::BaseObject
      #     field :currentUser, Types::User::UserType, null: true
      #   end
      #
      class GraphqlExplicitObject < Base
        MSG = 'GraphQL type `%<class_name>s` has no `object_type(...)` declaration. ' \
              'Add `object_type(ClassName)` to specify the underlying data object.'

        # @!method graphql_class?(node)
        def_node_matcher :graphql_class?, <<~PATTERN
          (class (const ...) (const ...) ...)
        PATTERN

        # @!method has_object_type_call?(node)
        def_node_matcher :has_object_type_call?, <<~PATTERN
          (class _ _ `(send nil? :object_type ...))
        PATTERN

        # @!method has_field_call?(node)
        def_node_matcher :has_field_call?, <<~PATTERN
          (class _ _ `(send nil? :field ...))
        PATTERN

        def on_class(node)
          return if !graphql_class?(node)
          return if !has_field_call?(node)
          return if has_object_type_call?(node)
          return if exempt_class_name?(node)

          class_name = node.children[0].const_name
          message = format(MSG, class_name: class_name)
          add_offense(node.children[0], message: message)
        end

        private

        def exempt_class_name?(node)
          class_name = node.children[0].const_name
          short_name = class_name.split('::').last

          # Exempt QueryType, MutationType, and Base* classes
          short_name.end_with?('QueryType') ||
            short_name == 'MutationType' ||
            short_name.start_with?('Base') ||
            short_name == 'Venture'
        end
      end
    end
  end
end
