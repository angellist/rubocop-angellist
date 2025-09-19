# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Extends Layout::ClassStructure to enforce stricter ordering:
      # - Nested classes before class methods
      # - Class methods before instance methods  
      # - GraphQL object_type before constants
      # - Class methods before GraphQL fields
      class ClassStructure < ::RuboCop::Cop::Layout::ClassStructure
        MSG = '`%<current>s` is supposed to appear before `%<previous>s`.'

        def on_class(class_node)
          super
          check_strict_ordering(class_node)
        end

        private

        def check_strict_ordering(class_node)
          return if class_node.sclass_type? # Skip singleton class nodes
          
          elements = class_elements(class_node)
          return if elements.empty?

          # Filter out nil elements and ensure we have valid nodes
          elements = elements.compact.select { |node| node.respond_to?(:type) }
          return if elements.empty?

          check_nested_classes_vs_class_methods(elements)
          check_class_methods_vs_instance_methods(elements)
          check_graphql_ordering(elements)
        end

        def check_nested_classes_vs_class_methods(elements)
          nested_class_indices = []
          class_method_indices = []

          elements.each_with_index do |node, index|
            next unless node # Skip nil nodes
            
            if nested_class?(node)
              nested_class_indices << [node, index]
            elsif class_method?(node)
              class_method_indices << [node, index]
            end
          end

          return if nested_class_indices.empty? || class_method_indices.empty?

          # Check if any nested class appears after any class method
          nested_class_indices.each do |nested_node, nested_idx|
            class_method_indices.each do |class_method_node, class_method_idx|
              if nested_idx > class_method_idx
                add_offense(
                  nested_node,
                  message: format(MSG, current: 'nested_classes', previous: 'public_class_methods')
                )
                break # Only report once per nested class
              end
            end
          end
        end

        def check_class_methods_vs_instance_methods(elements)
          class_method_indices = []
          instance_method_indices = []

          elements.each_with_index do |node, index|
            next unless node # Skip nil nodes
            
            if class_method?(node)
              class_method_indices << [node, index]
            elsif instance_method?(node)
              instance_method_indices << [node, index]
            end
          end

          return if class_method_indices.empty? || instance_method_indices.empty?

          # Check if any class method appears after any instance method
          class_method_indices.each do |class_method_node, class_method_idx|
            instance_method_indices.each do |instance_node, instance_idx|
              if class_method_idx > instance_idx
                add_offense(
                  class_method_node,
                  message: format(MSG, current: 'public_class_methods', previous: 'public_methods')
                )
                break # Only report once per class method
              end
            end
          end
        end

        def nested_class?(node)
          node.class_type? || node.module_type?
        end

        def class_method?(node)
          node.sclass_type? # class << self
        end

        def instance_method?(node)
          node.def_type? && !node.defs_type? # def method, not def self.method
        end

        def graphql_object_type?(node)
          node.send_type? && node.method_name == :object_type
        end

        def graphql_field?(node)
          return false unless node.send_type?
          [:field, :implements].include?(node.method_name)
        end

        def check_graphql_ordering(elements)
          check_graphql_object_type_vs_constants(elements)
          check_class_methods_vs_graphql_fields(elements)
        end

        def check_graphql_object_type_vs_constants(elements)
          object_type_indices = []
          constant_indices = []

          elements.each_with_index do |node, index|
            next unless node

            if graphql_object_type?(node)
              object_type_indices << [node, index]
            elsif constant?(node)
              constant_indices << [node, index]
            end
          end

          return if object_type_indices.empty? || constant_indices.empty?

          # Check if any object_type appears after any constant
          object_type_indices.each do |object_type_node, object_type_idx|
            constant_indices.each do |constant_node, constant_idx|
              if object_type_idx > constant_idx
                add_offense(
                  object_type_node,
                  message: format(MSG, current: 'graphql_object_types', previous: 'constants')
                )
                break
              end
            end
          end
        end

        def check_class_methods_vs_graphql_fields(elements)
          class_method_indices = []
          graphql_field_indices = []

          elements.each_with_index do |node, index|
            next unless node

            if class_method?(node)
              class_method_indices << [node, index]
            elsif graphql_field?(node)
              graphql_field_indices << [node, index]
            end
          end

          return if class_method_indices.empty? || graphql_field_indices.empty?

          # Check if any class method appears after any GraphQL field
          class_method_indices.each do |class_method_node, class_method_idx|
            graphql_field_indices.each do |graphql_field_node, graphql_field_idx|
              if class_method_idx > graphql_field_idx
                add_offense(
                  class_method_node,
                  message: format(MSG, current: 'public_class_methods', previous: 'graphql_fields')
                )
                break
              end
            end
          end
        end

        def constant?(node)
          node.casgn_type?
        end

        def class_elements(class_node)
          body = class_node.body
          return [] unless body

          if body.begin_type?
            body.children.compact
          elsif body.type?(:def, :send, :sclass, :class, :module, :casgn)
            [body]
          else
            []
          end
        end
      end
    end
  end
end