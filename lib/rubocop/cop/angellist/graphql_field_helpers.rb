# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Shared helpers for GraphQL field cops. Provides common methods for
      # detecting custom resolver defs, inserting keyword options, and
      # converting between camelCase and snake_case.
      module GraphqlFieldHelpers
        private

        # Checks whether the enclosing class/module defines a method with the
        # given name *directly* (not inside a nested class or module).
        def class_defines_method?(class_node, method_name)
          method_sym = method_name.is_a?(Symbol) ? method_name : method_name.to_sym
          class_node.body&.each_descendant(:def)&.any? do |def_node|
            def_node.method_name == method_sym &&
              def_node.each_ancestor(:class, :module).first == class_node
          end
        end

        # Returns true if the field's enclosing class defines a custom resolver
        # def matching +method_name+, meaning `resolver_method:` should be used
        # instead of `method:`.
        def resolver_method_needed?(node, method_name)
          enclosing_class = node.each_ancestor(:class, :module).first
          return false if !enclosing_class

          class_defines_method?(enclosing_class, method_name)
        end

        # Inserts a `method:` or `resolver_method:` keyword option into the
        # field call's hash arguments (before the first existing pair), or
        # appends it after the last argument if no hash is present.
        def insert_method_option(corrector, node, option_key, method_name)
          hash_node = find_hash_arg(node)
          if hash_node
            first_pair = hash_node.pairs.first
            corrector.insert_before(first_pair, "#{option_key}: :#{method_name}, ")
          else
            corrector.insert_after(node.last_argument, ", #{option_key}: :#{method_name}")
          end
        end

        # Finds the first hash-type argument node in a field call.
        def find_hash_arg(node)
          node.arguments.each do |arg|
            return arg if arg.hash_type?
          end
          nil
        end

        # Converts a camelCase string to snake_case.
        def underscore(str)
          str.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
        end
      end
    end
  end
end
