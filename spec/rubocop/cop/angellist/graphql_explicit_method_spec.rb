# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::GraphqlExplicitMethod, :config do
  let(:config) { RuboCop::Config.new('Angellist/GraphqlExplicitMethod' => { 'Enabled' => true }) }

  it 'registers an offense for snake_case field without method: or resolver_method:' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :post_money_valuation, Types::MoneyType, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:post_money_valuation` contains underscores but has no explicit `method:` or `resolver_method:` option. Add `method: :post_money_valuation` (if delegating to the data object) or `resolver_method: :post_money_valuation` (if a custom def exists in this class) and rename the field symbol to camelCase.
      end
    RUBY
  end

  it 'does not register an offense when method: is present' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      end
    RUBY
  end

  it 'does not register an offense when resolver_method: is present' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true
      end
    RUBY
  end

  it 'does not register an offense for single-word fields' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :id, ID, null: false
        field :email, String, null: true
        field :state, String, null: true
      end
    RUBY
  end

  it 'does not register an offense for camelCase fields' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, null: true
      end
    RUBY
  end

  it 'does not register an offense for fields with camelize: false' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :only_needs_kyc, Boolean, camelize: false, null: true
      end
    RUBY
  end

  it 'registers an offense for multiple snake_case fields' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :usd_to_cad_rate, Float, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:usd_to_cad_rate` contains underscores but has no explicit `method:` or `resolver_method:` option. Add `method: :usd_to_cad_rate` (if delegating to the data object) or `resolver_method: :usd_to_cad_rate` (if a custom def exists in this class) and rename the field symbol to camelCase.
        field :usd_to_inr_rate, Float, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:usd_to_inr_rate` contains underscores but has no explicit `method:` or `resolver_method:` option. Add `method: :usd_to_inr_rate` (if delegating to the data object) or `resolver_method: :usd_to_inr_rate` (if a custom def exists in this class) and rename the field symbol to camelCase.
      end
    RUBY
  end

  it 'does not register an offense when method: points to a different method' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :avatar_url, String, method: :avatar, null: true
      end
    RUBY
  end

  it 'flags snake_case field even when it has other options but no method:' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :closed_at, Types::DateTimeType, null: true, description: 'When it closed'
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:closed_at` contains underscores but has no explicit `method:` or `resolver_method:` option. Add `method: :closed_at` (if delegating to the data object) or `resolver_method: :closed_at` (if a custom def exists in this class) and rename the field symbol to camelCase.
      end
    RUBY
  end
end
