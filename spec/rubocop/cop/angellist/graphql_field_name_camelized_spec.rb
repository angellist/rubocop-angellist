# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::GraphqlFieldNameCamelized, :config do
  let(:config) { RuboCop::Config.new('Angellist/GraphqlFieldNameCamelized' => { 'Enabled' => true }) }

  it 'registers an offense for snake_case field name and auto-corrects' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :post_money_valuation, Types::MoneyType, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:post_money_valuation` uses snake_case. Use camelCase instead (e.g., `:postMoneyValuation`) with an explicit `method:` or `resolver_method:` option.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      end
    RUBY
  end

  it 'does not register an offense for camelCase field name' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      end
    RUBY
  end

  it 'does not register an offense for single-word field name' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :id, ID, method: :id, null: false
        field :email, String, method: :email, null: true
      end
    RUBY
  end

  it 'does not register an offense when camelize: false is set' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :only_needs_kyc, Boolean, camelize: false, null: true
      end
    RUBY
  end

  it 'auto-corrects snake_case field with existing method: by only renaming' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :created_at, Types::DateTimeType, method: :created_at, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:created_at` uses snake_case. Use camelCase instead (e.g., `:createdAt`) with an explicit `method:` or `resolver_method:` option.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :createdAt, Types::DateTimeType, method: :created_at, null: true
      end
    RUBY
  end

  it 'auto-corrects multiple snake_case fields' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :usd_to_cad_rate, Float, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:usd_to_cad_rate` uses snake_case. Use camelCase instead (e.g., `:usdToCadRate`) with an explicit `method:` or `resolver_method:` option.
        field :usd_to_inr_rate, Float, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:usd_to_inr_rate` uses snake_case. Use camelCase instead (e.g., `:usdToInrRate`) with an explicit `method:` or `resolver_method:` option.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :usdToCadRate, Float, method: :usd_to_cad_rate, null: true
        field :usdToInrRate, Float, method: :usd_to_inr_rate, null: true
      end
    RUBY
  end

  it 'auto-corrects multi-word field names' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :total_amount_raised_cents, Integer, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:total_amount_raised_cents` uses snake_case. Use camelCase instead (e.g., `:totalAmountRaisedCents`) with an explicit `method:` or `resolver_method:` option.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :totalAmountRaisedCents, Integer, method: :total_amount_raised_cents, null: true
      end
    RUBY
  end

  it 'auto-corrects with resolver_method: when custom def exists' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :post_money_valuation, Types::MoneyType, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:post_money_valuation` uses snake_case. Use camelCase instead (e.g., `:postMoneyValuation`) with an explicit `method:` or `resolver_method:` option.

        def post_money_valuation
          object.valuation
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true

        def post_money_valuation
          object.valuation
        end
      end
    RUBY
  end

  it 'auto-corrects field without type arg' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :created_at, null: true
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ GraphQL field `:created_at` uses snake_case. Use camelCase instead (e.g., `:createdAt`) with an explicit `method:` or `resolver_method:` option.
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :createdAt, method: :created_at, null: true
      end
    RUBY
  end

  it 'does not register an offense for camelize: false without type arg' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :only_needs_kyc, camelize: false, null: true
      end
    RUBY
  end
end
