# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # This cop forbids the use of `instance_variable_get` and `instance_variable_set`.
      # These methods bypass encapsulation and make code harder to reason about.
      #
      # @example
      #   # bad
      #   object.instance_variable_get(:@foo)
      #   object.instance_variable_set(:@foo, value)
      #
      #   # good
      #   object.foo
      #   object.foo = value
      #
      class ForbidInstanceVariableGetSet < Base
        MSG = 'Avoid using `instance_variable_get` or `instance_variable_set`. Prefer using public getters/setters.'

        RESTRICT_ON_SEND = %i[instance_variable_get instance_variable_set].freeze

        def on_send(node)
          add_offense(node)
        end
      end
    end
  end
end
