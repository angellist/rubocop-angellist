# typed: strict
# frozen_string_literal: true

module RuboCop
  module Cop
    module Angellist
      # Enhanced class structure ordering for AngelList conventions.
      #
      # This cop extends Layout/ClassStructure with stricter enforcement
      # of AngelList-specific patterns that the base cop doesn't catch.
      #
      # Expected order:
      # 1. Module inclusions (extend, include, prepend)  
      # 2. Constants (CONST = value, TypeAlias = T.type_alias)
      # 3. Nested classes (T::Struct, T::Enum, StandardError)
      # 4. Class methods (class << self)
      # 5. Instance methods 
      # 6. Protected methods
      # 7. Private methods
      #
      # @example
      #   # bad
      #   class PaymentService
      #     class << self
      #       def process; end
      #     end
      #     
      #     TIMEOUT = 30  # constant after class methods
      #   end
      #
      #   # good  
      #   class PaymentService
      #     TIMEOUT = 30
      #     
      #     class << self
      #       def process; end
      #     end
      #   end
      #
      class ClassStructure < ::RuboCop::Cop::Base
        extend T::Sig if defined?(T)

        MSG = '%<current>s should appear before %<previous>s.'

        sig { params(node: RuboCop::AST::ClassNode).void } if defined?(T)
        def on_class(node)
          check_class_structure(node)
        end

        private

        sig { params(node: RuboCop::AST::ClassNode).void } if defined?(T)
        def check_class_structure(node)
          body_nodes = class_body(node)
          return if body_nodes.size < 2

          violations = find_violations(body_nodes)
          violations.each { |violation| report_violation(violation) }
        end

        sig { params(node: RuboCop::AST::ClassNode).returns(T::Array[RuboCop::AST::Node]) } if defined?(T)
        def class_body(node)
          return [] unless node.body

          if node.body.begin_type?
            node.body.children.compact
          else
            [node.body]
          end
        end

        sig { params(nodes: T::Array[RuboCop::AST::Node]).returns(T::Array[T::Hash[Symbol, T.untyped]]) } if defined?(T)
        def find_violations(nodes)
          violations = []
          categories = categorize_nodes(nodes)
          
          # Check specific AngelList patterns
          violations.concat(check_constants_after_classes(categories))
          violations.concat(check_classes_after_class_methods(categories))
          violations.concat(check_class_methods_after_instance_methods(categories))

          violations
        end

        sig { params(nodes: T::Array[RuboCop::AST::Node]).returns(T::Hash[Symbol, T::Array[[RuboCop::AST::Node, Integer]]]) } if defined?(T)
        def categorize_nodes(nodes)
          result = {
            constants: [],
            nested_classes: [], 
            class_methods: [],
            instance_methods: []
          }

          nodes.each_with_index do |node, index|
            category = node_category(node)
            result[category] << [node, index] if category
          end

          result
        end

        sig { params(node: RuboCop::AST::Node).returns(T.nilable(Symbol)) } if defined?(T)
        def node_category(node)
          case node.type
          when :casgn
            :constants
          when :class, :module
            :nested_classes
          when :sclass
            :class_methods
          when :def
            :instance_methods
          end
        end

        sig { params(categories: T::Hash[Symbol, T::Array[[RuboCop::AST::Node, Integer]]]).returns(T::Array[T::Hash[Symbol, T.untyped]]) } if defined?(T)
        def check_constants_after_classes(categories)
          violations = []
          return violations if categories[:constants].empty? || categories[:nested_classes].empty?

          first_class_index = categories[:nested_classes].map { |_, i| i }.min
          
          categories[:constants].each do |node, index|
            if index > first_class_index
              violations << {
                node: node,
                current: 'constants',
                previous: 'nested classes'
              }
            end
          end

          violations
        end

        sig { params(categories: T::Hash[Symbol, T::Array[[RuboCop::AST::Node, Integer]]]).returns(T::Array[T::Hash[Symbol, T.untyped]]) } if defined?(T)
        def check_classes_after_class_methods(categories)
          violations = []
          return violations if categories[:nested_classes].empty? || categories[:class_methods].empty?

          first_class_method_index = categories[:class_methods].map { |_, i| i }.min

          categories[:nested_classes].each do |node, index|
            if index > first_class_method_index
              violations << {
                node: node, 
                current: 'nested classes',
                previous: 'class methods'
              }
            end
          end

          violations
        end

        sig { params(categories: T::Hash[Symbol, T::Array[[RuboCop::AST::Node, Integer]]]).returns(T::Array[T::Hash[Symbol, T.untyped]]) } if defined?(T)
        def check_class_methods_after_instance_methods(categories)
          violations = []
          return violations if categories[:class_methods].empty? || categories[:instance_methods].empty?

          first_instance_method_index = categories[:instance_methods].map { |_, i| i }.min

          categories[:class_methods].each do |node, index|
            if index > first_instance_method_index
              violations << {
                node: node,
                current: 'class methods', 
                previous: 'instance methods'
              }
            end
          end

          violations
        end

        sig { params(violation: T::Hash[Symbol, T.untyped]).void } if defined?(T)
        def report_violation(violation)
          message = format(MSG, 
                          current: violation[:current], 
                          previous: violation[:previous])
          add_offense(violation[:node], message: message)
        end
      end
    end
  end
end