# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::GraphqlExplicitObject, :config do
  let(:config) { RuboCop::Config.new('Angellist/GraphqlExplicitObject' => { 'Enabled' => true }) }

  it 'registers an offense for a type class with fields but no object_type' do
    expect_offense(<<~RUBY)
      class Types::Admin::DealAccessLinkType < Types::Venture
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL type `Types::Admin::DealAccessLinkType` has no `object_type(...)` declaration. Add `object_type(ClassName)` to specify the underlying data object.
        field :id, ID, null: false
      end
    RUBY
  end

  it 'does not register an offense when object_type is present' do
    expect_no_offenses(<<~RUBY)
      class Types::Admin::DealAccessLinkType < Types::Venture
        object_type(DealAccessLink)

        field :id, ID, null: false
      end
    RUBY
  end

  it 'does not register an offense for QueryType classes' do
    expect_no_offenses(<<~RUBY)
      class QueryType < Types::BaseObject
        field :currentUser, Types::User::UserType, null: true
      end
    RUBY
  end

  it 'does not register an offense for nested QueryType classes' do
    expect_no_offenses(<<~RUBY)
      class Types::Invest::QueryType < Types::BaseObject
        field :deals, Types::DealType, null: false
      end
    RUBY
  end

  it 'does not register an offense for MutationType classes' do
    expect_no_offenses(<<~RUBY)
      class MutationType < Types::BaseObject
        field :createUser, mutation: Mutations::CreateUser
      end
    RUBY
  end

  it 'does not register an offense for nested MutationType classes' do
    expect_no_offenses(<<~RUBY)
      class Types::Invest::MutationType < Types::BaseObject
        field :createRound, mutation: Mutations::CreateRound
      end
    RUBY
  end

  it 'does not register an offense for Base* classes' do
    expect_no_offenses(<<~RUBY)
      class Types::BaseObject < GraphQL::Schema::Object
        field :readOnly, Boolean, null: false
      end
    RUBY
  end

  it 'does not register an offense for Venture base class' do
    expect_no_offenses(<<~RUBY)
      class Types::Venture < Types::BaseObject
        field :id, ID, null: false
      end
    RUBY
  end

  it 'does not register an offense for classes without field calls' do
    expect_no_offenses(<<~RUBY)
      class Types::SomeHelper < Types::BaseObject
        def some_method
          'hello'
        end
      end
    RUBY
  end

  it 'registers an offense for a type class in a module' do
    expect_offense(<<~RUBY)
      module Types
        class AddressType < BaseObject
              ^^^^^^^^^^^ GraphQL type `AddressType` has no `object_type(...)` declaration. Add `object_type(ClassName)` to specify the underlying data object.
          field :city, String, null: true
        end
      end
    RUBY
  end

  it 'does not register an offense for CPTR types with object_type' do
    expect_no_offenses(<<~RUBY)
      class CPTR::Types::MemberType < CPTR::Types::BaseObject
        object_type(CPTR::Member)

        field :id, ID, null: false
      end
    RUBY
  end

  it 'registers an offense for CPTR types without object_type' do
    expect_offense(<<~RUBY)
      class CPTR::Types::SomeType < CPTR::Types::BaseObject
            ^^^^^^^^^^^^^^^^^^^^^ GraphQL type `CPTR::Types::SomeType` has no `object_type(...)` declaration. Add `object_type(ClassName)` to specify the underlying data object.
        field :id, ID, null: false
      end
    RUBY
  end
end
