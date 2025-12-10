# frozen_string_literal: true
# typed: false

require 'rubocop'

module RuboCop
  module Cop
    module Angellist
      # Enforces that certain methods can only be called from specific files or directories
      #
      # @example Configuration in .rubocop.yml
      #   Angellist/EnforceMethodCallSites:
      #     Enabled: true
      #     Restrictions:
      #       - Module: IncomingWires::StateService
      #         Methods: [hold!, transfer!, mark_pending_return!, return!]  # optional, defaults to all
      #         AllowedCallSites:
      #           - app/models/incoming_wire.rb
      #           - app/services/incoming_wires/state_service.rb
      #       - Module: SomeOther::Service
      #         AllowedCallSites:
      #           - app/controllers/admin/**/*.rb
      class EnforceMethodCallSites < Base
        def on_send(node)
          check_method_call(node)
          check_dynamic_send(node)
        end

        def on_csend(node)
          # Handle safe navigation operator (&.)
          check_method_call(node)
          check_dynamic_send(node)
        end

        def on_lvasgn(node)
          # Track local variable assignments to constants
          return if !node.children[1]&.const_type?

          @const_assignments ||= {}
          var_name = node.children[0]
          const_name = extract_const_name(node.children[1])
          @const_assignments[var_name] = const_name if const_name
        end

        def on_ivasgn(node)
          # Track instance variable assignments to constants
          return if !node.children[1]&.const_type?

          @const_assignments ||= {}
          var_name = node.children[0]
          const_name = extract_const_name(node.children[1])
          @const_assignments[var_name] = const_name if const_name
        end

        private

        def check_method_call(node)
          # Special handling for .method(:method_name) calls
          if node.method_name == :method && node.arguments.first&.sym_type?
            check_method_reference(node)
            return
          end

          restrictions.each do |restriction|
            next if !matches_restriction?(node, restriction)
            next if allowed_call_site?(restriction)

            add_offense(node, message: build_message(node, restriction))
          end
        end

        def check_method_reference(node)
          # Check for Module.method(:method_name) pattern
          method_name = node.arguments.first.value.to_sym
          receiver_module = resolve_receiver_module(node.receiver)
          return if !receiver_module

          restrictions.each do |restriction|
            methods = parse_methods(restriction['Methods'])
            next if methods != :all && !methods.include?(method_name)

            expected_module = normalize_module_name(restriction['Module'])
            next if normalize_module_name(receiver_module) != expected_module
            next if allowed_call_site?(restriction)

            add_offense(node, message: "Method reference to #{receiver_module}.#{method_name} can only be made from: #{(restriction['AllowedCallSites'] || []).join(', ')}")
          end
        end

        def check_dynamic_send(node)
          # Check for send(:method_name, ...) or public_send(:method_name, ...)
          return if ![:send, :public_send, :__send__].include?(node.method_name)
          return if !(node.arguments.first&.sym_type? || node.arguments.first&.str_type?)

          method_name = node.arguments.first.value.to_sym
          receiver_module = resolve_receiver_module(node.receiver)
          return if !receiver_module

          restrictions.each do |restriction|
            methods = parse_methods(restriction['Methods'])
            next if methods != :all && !methods.include?(method_name)

            expected_module = normalize_module_name(restriction['Module'])
            next if normalize_module_name(receiver_module) != expected_module
            next if allowed_call_site?(restriction)

            add_offense(node, message: "Dynamic call to #{receiver_module}.#{method_name} can only be made from: #{(restriction['AllowedCallSites'] || []).join(', ')}")
          end
        end

        def restrictions
          @restrictions ||= cop_config['Restrictions'] || []
        end

        def matches_restriction?(node, restriction)
          # Skip dynamic send methods themselves - we handle those separately
          return false if [:send, :public_send, :__send__].include?(node.method_name)

          # Check if method matches (defaults to all if not specified)
          methods = parse_methods(restriction['Methods'])
          return false if methods != :all && !methods.include?(node.method_name)

          # Check if receiver matches the module/class
          expected_module = restriction['Module']
          return false if !expected_module

          # Try to resolve the actual module name (handles variables and constants)
          actual_module = resolve_receiver_module(node.receiver)
          return false if actual_module.nil?

          normalize_module_name(actual_module) == normalize_module_name(expected_module)
        end

        def resolve_receiver_module(receiver)
          return if !receiver

          case receiver.type
          when :const
            # Direct constant reference
            extract_const_name(receiver)
          when :lvar, :ivar
            # Variable that might hold a constant
            @const_assignments ||= {}
            var_name = receiver.children[0]
            @const_assignments[var_name]
          when :send, :csend
            # Method call that might return a constant (e.g., self.class)
            # For now, we'll just try to get the source
            receiver.source
          else
            receiver.source
          end
        end

        def extract_const_name(node)
          return if !node&.const_type?

          parts = []
          current = node
          while current&.const_type?
            parts.unshift(current.children[1].to_s)
            current = current.children[0]
          end
          parts.join('::')
        end

        def normalize_module_name(module_name)
          # Remove leading :: to normalize fully-qualified names
          module_name.to_s.gsub(/^::/, '')
        end

        def parse_methods(methods)
          return :all if [nil, 'all', :all].include?(methods)

          Array(methods).map(&:to_sym)
        end

        def allowed_call_site?(restriction)
          file_path = processed_source.file_path
          allowed_call_sites = restriction['AllowedCallSites'] || []

          allowed_call_sites.any? do |pattern|
            if pattern.include?('**') || pattern.include?('*')
              # Handle glob patterns
              File.fnmatch?(pattern, file_path)
            else
              # Handle exact file names or endings
              file_path.end_with?(pattern)
            end
          end
        end

        def build_message(node, restriction)
          allowed_sites = restriction['AllowedCallSites'] || []
          "#{node.receiver.source}.#{node.method_name} can only be called from: #{allowed_sites.join(', ')}"
        end
      end
    end
  end
end
