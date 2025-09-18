# typed: strict  
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Layout::ClassStructure, :config do
  let(:config_path) { File.expand_path('../../../../rubocop.yml', __dir__) }
  let(:config) { RuboCop::ConfigLoader.load_file(config_path) }

  # Test the Shopify Layout/ClassStructure cop configuration
  # This tests what the base RuboCop cop actually detects

  context 'configuration verification' do
    let(:class_structure_config) { config['Layout/ClassStructure'] }

    it 'enables Layout/ClassStructure with warning severity' do
      expect(class_structure_config['Enabled']).to be true
      expect(class_structure_config['Severity']).to eq 'warning'
    end

    it 'configures expected order for AngelList patterns' do
      expected_order = %w[
        module_inclusion
        constants
        public_class_methods
        public_methods
        protected_methods
        private_methods
      ]
      expect(class_structure_config['ExpectedOrder']).to eq expected_order
    end

    it 'maps categories to correct AST node types' do
      categories = class_structure_config['Categories']

      expect(categories['module_inclusion']).to include('extend', 'include', 'prepend')
      expect(categories['constants']).to include('casgn')
      expect(categories['public_class_methods']).to include('sclass') 
      expect(categories['public_methods']).to include('def')
      expect(categories['protected_methods']).to include('protected')
      expect(categories['private_methods']).to include('private')
    end
  end

  context 'with basic valid structures' do
    it 'allows simple service class' do
      expect_no_offenses(<<~RUBY)
        class SimpleService
          extend T::Sig

          TIMEOUT = 30

          class << self
            def perform
              'logic'
            end
          end
        end
      RUBY
    end
  end

  context 'with violations the base cop detects' do
    it 'detects constants before module inclusions' do
      expect_offense(<<~RUBY)
        class BadOrder
          TIMEOUT = 30

          extend T::Sig
          ^^^^^^^^^^^^^ `module_inclusion` is supposed to appear before `constants`.

          class << self
            def perform; end
          end
        end
      RUBY
    end
  end
end