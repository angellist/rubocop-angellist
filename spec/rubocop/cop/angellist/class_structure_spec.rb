# typed: strict
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::ClassStructure, :config do
  let(:config) { RuboCop::Config.new }

  context 'inherits basic Layout/ClassStructure functionality' do
    it 'detects module inclusions after constants' do
      expect_offense(<<~RUBY)
        class BadOrder
          TIMEOUT = 30

          extend T::Sig
          ^^^^^^^^^^^^^ Angellist/ClassStructure: `module_inclusion` is supposed to appear before `constants`.
          include ActiveSupport::Concern
        end
      RUBY
    end

    it 'allows constants before nested classes (correct order)' do
      expect_no_offenses(<<~RUBY)
        class GoodOrder
          # 1. Module inclusions
          extend T::Sig

          # 2. Constants
          TIMEOUT = 30

          # 3. Nested classes
          class InnerClass; end
        end
      RUBY
    end

    it 'detects public methods after private methods' do
      expect_offense(<<~RUBY)
        class BadOrder
          private

          def private_method
            'private'
          end

          public

          def public_method
          ^^^^^^^^^^^^^^^^^ Angellist/ClassStructure: `public_methods` is supposed to appear before `private_methods`.
            'public'
          end
        end
      RUBY
    end

    it 'allows proper basic ordering' do
      expect_no_offenses(<<~RUBY)
        class ProperOrder
          extend T::Sig
          include ActiveSupport::Concern
          prepend SomeModule

          TIMEOUT = 30
          MAX_RETRIES = 3

          class << self
            def find(id)
              new(id)
            end
          end

          def initialize(id)
            @id = id
          end

          protected

          def internal_method
            'internal'
          end

          private

          def secret_method
            'secret'
          end
        end
      RUBY
    end
  end

  context 'detects AngelList-specific violations' do
    it 'detects nested classes appearing after class methods' do
      expect_offense(<<~RUBY)
        class Service
          extend T::Sig
          TIMEOUT = 30

          class << self
            def process
              new.process
            end
          end

          class Error < StandardError
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/ClassStructure: `nested_classes` is supposed to appear before `public_class_methods`.
          end
        end
      RUBY
    end

    it 'detects class methods appearing after instance methods' do
      expect_offense(<<~RUBY)
        class Model
          extend T::Sig

          def name
            @name
          end

          class << self
          ^^^^^^^^^^^^^ Angellist/ClassStructure: `public_class_methods` is supposed to appear before `public_methods`.
            def find(id)
              new(id)
            end
          end
        end
      RUBY
    end

    it 'detects both violations in the same class' do
      expect_offense(<<~RUBY)
        class ComplexClass
          def instance_method
            'instance'
          end

          class << self
          ^^^^^^^^^^^^^ Angellist/ClassStructure: `public_class_methods` is supposed to appear before `public_methods`.
            def class_method
              'class'
            end
          end

          class InnerError < StandardError
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/ClassStructure: `nested_classes` is supposed to appear before `public_class_methods`.
          end
        end
      RUBY
    end

    it 'detects incorrect GraphQL ordering' do
      expect_offense(<<~RUBY)
        class Types::PaymentType < Types::BaseObject
          RelationType = T.type_alias { T.any(PrivateRelation, PublicRelation) }

          object_type(Payment)
          ^^^^^^^^^^^^^^^^^^^^ Angellist/ClassStructure: `graphql_object_types` is supposed to appear before `constants`.

          implements Types::AccountInterface
          field :amount, Types::MoneyType

          class << self
          ^^^^^^^^^^^^^ Angellist/ClassStructure: `public_class_methods` is supposed to appear before `graphql_fields`.
            def authorized?(object, context)
              OutgoingWirePolicy.new(context[:current_user], object).show?
            end
          end
        end
      RUBY
    end
  end

  context 'allows correct Angellist-specific ordering' do
    it 'allows properly ordered class' do
      expect_no_offenses(<<~RUBY)
        class PaymentService
          # I. Module inclusions
          extend T::Sig
          include ActiveSupport::Concern

          # II. Constants
          TIMEOUT = 30
          MAX_RETRIES = 3

          # III. Nested classes
          class PaymentError < StandardError; end

          class PaymentRequest < T::Struct
            const :amount, BigDecimal
          end

          # IV. sClass methods
          class << self
            def process(request)
              new(request).process
            end
          end

          # V. Instance methods
          def initialize(request)
            @request = request
          end

          def process
            validate!
          end

          private

          def validate!
            raise PaymentError if invalid?
          end
        end
      RUBY
    end

    it 'allows T::Enum with proper ordering' do
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
            def active
              where(status: 'active')
            end
          end

          def full_name
            "\#{first_name} \#{last_name}"
          end
        end
      RUBY
    end

    it 'allows properly ordered graphql type class' do
      expect_no_offenses(<<~RUBY)
        class Types::PaymentType < Types::BaseObject
          # 1. Object type first
          object_type(Payment)

          # 2. Constants
          RelationType = T.type_alias { T.any(PrivateRelation, PublicRelation) }
          VALID_EVENTS = [:submit, :approve, :cancel]

          # 3. Class methods
          class << self
            sig { params(object: Payment, context: Context)}
            def authorized?(object, context)
              OutgoingWirePolicy.new(context[:current_user], object).show?
            end
          end

          # 4. GraphQL fields/interfaces
          implements Types::AccountInterface
          implements Types::LedgerInterface
          field :amount, Types::MoneyType
          field :relation, Types::RelationType

          # 5. Instance methods
          sig { returns(Payment::Status) }
          def calculated_status
            Payment::CalculateStatusService.calculated_status(object)
          end
        end
      RUBY
    end
  end
end
