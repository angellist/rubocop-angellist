# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Checks for usages of literal `@>` SQL operator in `.where` calls
      # and recommends using ActiveRecord's `.where.contains` instead.
      #
      # The `@>` operator is PostgreSQL's containment operator for arrays
      # and JSONB columns. ActiveRecord provides a cleaner API via
      # `.where.contains` that avoids writing raw SQL.
      #
      # @example
      #   # bad
      #   Model.where("tags @> ARRAY[?]", "ruby")
      #   Model.where("data @> ?::jsonb", value)
      #   scope.where("column @> '{\"key\": \"value\"}'")
      #
      #   # good
      #   Model.where.contains(tags: ["ruby"])
      #   Model.where.contains(data: { key: "value" })
      #
      class PreferWhereContains < ::RuboCop::Cop::Base
        MSG = 'Use `.where.contains(column: value)` instead of literal `@>` SQL in `.where`.'

        RESTRICT_ON_SEND = [:where].freeze

        sig { params(node: RuboCop::AST::SendNode).void }
        def on_send(node)
          return if !node.arguments?

          first_arg = node.first_argument
          return if !first_arg || !string_containing_contains_operator?(first_arg)

          add_offense(node)
        end

        private

        sig { params(node: RuboCop::AST::Node).returns(T::Boolean) }
        def string_containing_contains_operator?(node)
          case node.type
          when :str
            T.cast(node, RuboCop::AST::StrNode).value.include?('@>')
          when :dstr
            node.children.any? { |child| child.str_type? && T.cast(child, RuboCop::AST::StrNode).value.include?('@>') }
          else
            false
          end
        end
      end
    end
  end
end
