# typed: strict
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::ClassStructure, :config do
  let(:config) { RuboCop::Config.new }

  # Test the enhanced AngelList ClassStructure cop
  # This extends beyond what the base Shopify cop detects

  context 'with valid AngelList class structures' do
    it 'allows properly ordered service class' do
      expect_no_offenses(<<~RUBY)
        class PaymentService
          extend T::Sig

          TIMEOUT = 30
          MAX_RETRIES = 3

          class PaymentRequest < T::Struct
            const :amount, BigDecimal
          end

          class << self
            def process(request)
              'logic'
            end
          end
        end
      RUBY
    end

    it 'allows properly ordered model class' do
      expect_no_offenses(<<~RUBY)
        class User < ApplicationRecord
          extend T::Sig

          VALID_STATUSES = %w[active inactive].freeze

          class Status < T::Enum
            enums do
              Active = new('active')
              Inactive = new('inactive')
            end
          end

          class << self
            def active_users
              where(status: 'active')
            end
          end

          def full_name
            "\#{first_name} \#{last_name}"
          end

          private

          def validate_name
            'validation logic'
          end
        end
      RUBY
    end
  end

  context 'with AngelList-specific violations' do
    it 'detects constants appearing after nested classes' do
      expect_offense(<<~RUBY)
        class DataService
          extend T::Sig

          class DataStruct < T::Struct
            const :value, String
          end

          BATCH_SIZE = 100
          ^^^^^^^^^^^^^^^^ Angellist/ClassStructure: constants should appear before nested classes.
        end
      RUBY
    end

    it 'detects nested classes appearing after class methods' do
      expect_offense(<<~RUBY)
        class PaymentService
          extend T::Sig

          TIMEOUT = 30

          class << self
            def process; end
          end

          class PaymentStruct < T::Struct
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/ClassStructure: nested classes should appear before class methods.
            const :amount, BigDecimal
          end
        end
      RUBY
    end

    it 'detects class methods appearing after instance methods' do
      expect_offense(<<~RUBY)
        class User < ApplicationRecord
          extend T::Sig

          VALID_ROLES = %w[admin user].freeze

          def full_name
            'name'
          end

          class << self
          ^^^^^^^^^^^^^ Angellist/ClassStructure: class methods should appear before instance methods.
            def admins
              where(role: 'admin')
            end
          end
        end
      RUBY
    end
  end
end
