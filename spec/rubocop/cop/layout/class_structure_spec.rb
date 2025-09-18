# typed: strict
# frozen_string_literal: true

RSpec.describe 'Layout/ClassStructure configuration', :config do
  let(:config_path) { File.expand_path('../../../rubocop.yml', __dir__) }
  let(:config) { RuboCop::ConfigLoader.load_file(config_path) }

  def inspect_source(source, file_path = 'test.rb')
    processed_source = RuboCop::ProcessedSource.new(source, RuboCop::TargetRuby.supported_versions.last, file_path)
    commissioner = RuboCop::Cop::Commissioner.new([RuboCop::Cop::Layout::ClassStructure.new(config)])
    commissioner.investigate(processed_source)
    commissioner.cops.first.offenses
  end

  context 'with well-structured AngelList patterns' do
    it 'allows properly ordered RuboCop cop structure' do
      offenses = inspect_source(<<~RUBY)
        class GoodCopStructure < RuboCop::Cop::Base
          extend T::Sig
          extend AutoCorrector

          MSG = 'Use better approach'
          RESTRICT_ON_SEND = [:bad_method].freeze

          class << self
            def restrict_on_send
              RESTRICT_ON_SEND
            end
          end

          private

          def on_send(node)
            add_offense(node, message: MSG)
          end

          def autocorrect(corrector, node)
            corrector.replace(node, 'good_method')
          end
        end
      RUBY

      expect(offenses).to be_empty
    end

    it 'allows properly ordered service class structure' do
      offenses = inspect_source(<<~RUBY)
        class WealthSourcesService
          include ServiceHelpers
          extend T::Sig

          TIMEOUT = 30
          VERSION = '1.2.0'

          class << self
            def perform(params)
              new(params).call
            end

            def validate_params(params)
              params.present?
            end

            private

            def build_request(params)
              params.transform_keys(&:to_s)
            end
          end

          private

          def initialize(params)
            @params = params
          end

          def call
            'service result'
          end
        end
      RUBY

      expect(offenses).to be_empty
    end

    it 'allows properly ordered controller with instance methods' do
      offenses = inspect_source(<<~RUBY)
        class UsersController
          extend T::Sig
          include AuthHelpers

          DEFAULT_LIMIT = 100
          MAX_PAGE_SIZE = 1000

          def index
            render json: paginated_users
          end

          def show
            render json: find_user
          end

          def create
            user = build_user
            if user.save
              render json: user, status: :created
            else
              render json: { errors: user.errors }
            end
          end

          private

          def paginated_users
            users.limit(params[:limit] || DEFAULT_LIMIT)
          end

          def find_user
            users.find(params[:id])
          end

          def build_user
            users.build(user_params)
          end
        end
      RUBY

      expect(offenses).to be_empty
    end

    it 'allows properly ordered class with protected methods' do
      offenses = inspect_source(<<~RUBY)
        class ApplicationController
          include Pundit::Authorization
          extend T::Sig

          DEFAULT_TIMEOUT = 30

          def index
            render json: current_user
          end

          protected

          def verify_authorized
            super unless is_a?(DeviseController)
          end

          def current_ability
            @current_ability ||= Ability.new(current_user)
          end

          private

          def user_not_authorized
            redirect_to root_path
          end
        end
      RUBY

      expect(offenses).to be_empty
    end

    it 'allows constants-only class with private methods' do
      offenses = inspect_source(<<~RUBY)
        class ConfigurationManager
          extend T::Sig

          DEFAULT_CONFIG = { timeout: 30, retries: 3 }.freeze
          MAX_RETRIES = 5
          API_VERSION = 'v1'

          private

          def initialize
            @config = DEFAULT_CONFIG.dup
          end

          def validate_config
            raise 'Invalid config' unless @config.key?(:timeout)
          end
        end
      RUBY

      expect(offenses).to be_empty
    end

    it 'allows multiple InfoStruct subclasses in correct order' do
      offenses = inspect_source(<<~RUBY)
        class DataStructures
          extend T::Sig

          SCHEMA_VERSION = 1

          class UserInfo < T::Struct
            const :id, Integer
            const :name, String
            const :email, String
          end

          class CompanyInfo < T::Struct
            const :id, Integer
            const :name, String
            const :size, T.nilable(String)
          end

          class InvestmentInfo < T::Struct
            const :amount, BigDecimal
            const :date, Date
            const :status, String
          end

          class << self
            def build_user_info(attrs)
              UserInfo.new(attrs)
            end

            def build_company_info(attrs)
              CompanyInfo.new(attrs)
            end
          end

          def process_data
            'processing'
          end

          private

          def validate_structs
            'validation logic'
          end
        end
      RUBY

      expect(offenses).to be_empty
    end
  end

  context 'with incorrectly structured classes' do
    it 'detects constants appearing before module inclusions' do
      offenses = inspect_source(<<~RUBY)
        class BadConstantsFirst < RuboCop::Cop::Base
          MSG = 'This constant should come after extensions'
          RESTRICT_ON_SEND = [:method].freeze

          extend T::Sig
          extend AutoCorrector

          def on_send(node)
            add_offense(node)
          end

          private

          def helper_method
            'helper'
          end
        end
      RUBY

      expect(offenses.size).to eq 1
      expect(offenses.first.message).to include('constants')
      expect(offenses.first.message).to include('module_inclusion')
      expect(offenses.first.severity).to eq :warning
      expect(offenses.first.line).to eq 2  # MSG line
    end

    it 'detects class methods appearing after private methods' do
      offenses = inspect_source(<<~RUBY)
        class BadClassMethodsAfterPrivate
          extend T::Sig
          include SomeModule

          TIMEOUT = 30

          private

          def private_helper
            'private should come at bottom'
          end

          class << self
            def class_method
              'class methods should come before private'
            end
          end
        end
      RUBY

      expect(offenses.size).to be >= 1
      class_method_offense = offenses.find { |o| o.message.include?('public_class_methods') }
      expect(class_method_offense).not_to be_nil
      expect(class_method_offense.line).to eq 12  # class << self line
    end

    it 'detects instance methods appearing before class methods' do
      offenses = inspect_source(<<~RUBY)
        class BadInstanceBeforeClass
          include ServiceHelpers

          TIMEOUT = 30

          def instance_method
            'instance methods should come after class methods'
          end

          class << self
            def class_method
              'class methods should come before instance methods'
            end
          end

          private

          def private_method
            'private'
          end
        end
      RUBY

      expect(offenses.size).to be >= 1
      class_method_offense = offenses.find { |o| o.message.include?('public_class_methods') }
      expect(class_method_offense).not_to be_nil
      expect(class_method_offense.line).to eq 10  # class << self line
    end

    it 'detects nested structs appearing before constants' do
      offenses = inspect_source(<<~RUBY)
        class BadStructOrder
          extend T::Sig

          class UserInfo < T::Struct
            const :id, Integer
            const :name, String
          end

          SCHEMA_VERSION = 1
          MAX_RECORDS = 1000

          class << self
            def build_user(attrs)
              UserInfo.new(attrs)
            end
          end

          private

          def validate_schema
            'validation'
          end
        end
      RUBY

      expect(offenses.size).to be >= 1
      # Should detect constants appearing after nested classes
      constant_offense = offenses.find { |o| o.message.include?('constants') && o.line >= 9 }
      expect(constant_offense).not_to be_nil
    end

    it 'detects nested structs appearing after class methods' do
      offenses = inspect_source(<<~RUBY)
        class BadStructAfterClassMethods
          include DataHelpers

          SCHEMA_VERSION = 2

          class << self
            def process_data
              'processing'
            end
          end

          class UserInfo < T::Struct
            const :id, Integer
            const :email, String
          end

          def validate
            'validation'
          end
        end
      RUBY

      expect(offenses.size).to be >= 1
      # Should detect nested class appearing after class << self
      struct_offense = offenses.find { |o| o.line == 12 }  # UserInfo class line
      expect(struct_offense).not_to be_nil
    end

    it 'detects protected methods appearing before public methods' do
      offenses = inspect_source(<<~RUBY)
        class BadProtectedOrder
          include AuthHelpers

          DEFAULT_TIMEOUT = 30

          protected

          def verify_authorization
            'protected method too early'
          end

          def public_action
            'public method should come before protected'
          end

          private

          def helper_method
            'private'
          end
        end
      RUBY

      expect(offenses.size).to be >= 1
      # Should detect public method appearing after protected
      public_method_offense = offenses.find { |o| o.message.include?('public_methods') }
      expect(public_method_offense).not_to be_nil
      expect(public_method_offense.line).to eq 12  # public_action line
    end

    it 'detects constants appearing after class methods' do
      offenses = inspect_source(<<~RUBY)
        class BadConstantsAfterClass
          extend T::Sig

          class << self
            def perform
              'class method'
            end
          end

          TIMEOUT = 30
          VERSION = '1.0'

          def instance_method
            'instance'
          end

          private

          def helper
            'private'
          end
        end
      RUBY

      expect(offenses.size).to be >= 1
      # Should detect constants appearing after class << self
      constant_offense = offenses.find { |o| o.message.include?('constants') }
      expect(constant_offense).not_to be_nil
      expect(constant_offense.line).to be_between(10, 11)  # TIMEOUT or VERSION line
    end
  end

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
      expect(categories['constants']).to include('casgn')  # constant assignment AST node
      expect(categories['public_class_methods']).to include('sclass')  # class << self AST node
      expect(categories['public_methods']).to include('def')  # method definition AST node
      expect(categories['protected_methods']).to include('protected')
      expect(categories['private_methods']).to include('private')
    end
  end
end
