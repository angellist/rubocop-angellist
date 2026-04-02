# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::GraphqlResolverMethod, :config do
  let(:config) { RuboCop::Config.new('Angellist/GraphqlResolverMethod' => { 'Enabled' => true }) }

  it 'registers an offense when method: is used and a matching def exists' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
                                                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `method: :post_money_valuation` will call `object.post_money_valuation` (the data object), but this class defines `def post_money_valuation` which is a resolver on the type class. Use `resolver_method: :post_money_valuation` instead so the custom resolver is called.

        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true

        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY
  end

  it 'does not register an offense when method: is used and no matching def exists' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :closedAt, Types::DateTimeType, method: :closed_at, null: true
        field :roundType, String, method: :round_type, null: true
      end
    RUBY
  end

  it 'does not register an offense when resolver_method: is already used' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, resolver_method: :post_money_valuation, null: true

        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY
  end

  it 'does not register an offense when field has no method: option' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :id, ID, null: false

        def id
          object.id.hash
        end
      end
    RUBY
  end

  it 'registers an offense for multiple fields with matching defs' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :usdToCadRate, Float, method: :usd_to_cad_rate, null: true
                                    ^^^^^^^^^^^^^^^^^^^^^^^^ `method: :usd_to_cad_rate` will call `object.usd_to_cad_rate` (the data object), but this class defines `def usd_to_cad_rate` which is a resolver on the type class. Use `resolver_method: :usd_to_cad_rate` instead so the custom resolver is called.
        field :usdToInrRate, Float, method: :usd_to_inr_rate, null: true
                                    ^^^^^^^^^^^^^^^^^^^^^^^^ `method: :usd_to_inr_rate` will call `object.usd_to_inr_rate` (the data object), but this class defines `def usd_to_inr_rate` which is a resolver on the type class. Use `resolver_method: :usd_to_inr_rate` instead so the custom resolver is called.

        def usd_to_cad_rate
          ExchangeRate.usd_to_cad
        end

        def usd_to_inr_rate
          ExchangeRate.usd_to_inr
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :usdToCadRate, Float, resolver_method: :usd_to_cad_rate, null: true
        field :usdToInrRate, Float, resolver_method: :usd_to_inr_rate, null: true

        def usd_to_cad_rate
          ExchangeRate.usd_to_cad
        end

        def usd_to_inr_rate
          ExchangeRate.usd_to_inr
        end
      end
    RUBY
  end

  it 'does not register an offense when method: points to a different name than any def' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :avatarUrl, String, method: :avatar, null: true

        def something_else
          'hello'
        end
      end
    RUBY
  end

  it 'registers an offense inside a module' do
    expect_offense(<<~RUBY)
      module Types
        class MyType < Types::BaseObject
          field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
                                                       ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `method: :post_money_valuation` will call `object.post_money_valuation` (the data object), but this class defines `def post_money_valuation` which is a resolver on the type class. Use `resolver_method: :post_money_valuation` instead so the custom resolver is called.

          def post_money_valuation
            object&.valuation&.to_money
          end
        end
      end
    RUBY
  end

  it 'handles method: with other keyword args in different positions' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, null: true, method: :post_money_valuation, description: 'PMV'
                                                                 ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `method: :post_money_valuation` will call `object.post_money_valuation` (the data object), but this class defines `def post_money_valuation` which is a resolver on the type class. Use `resolver_method: :post_money_valuation` instead so the custom resolver is called.

        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY
  end

  it 'registers an offense for field without type arg when method: matches a def' do
    expect_offense(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, method: :post_money_valuation, null: true
                                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ `method: :post_money_valuation` will call `object.post_money_valuation` (the data object), but this class defines `def post_money_valuation` which is a resolver on the type class. Use `resolver_method: :post_money_valuation` instead so the custom resolver is called.

        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, resolver_method: :post_money_valuation, null: true

        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY
  end

  it 'does not flag private defs in a different class' do
    expect_no_offenses(<<~RUBY)
      class Types::MyType < Types::BaseObject
        field :postMoneyValuation, Types::MoneyType, method: :post_money_valuation, null: true
      end

      class Types::OtherType < Types::BaseObject
        def post_money_valuation
          object&.valuation&.to_money
        end
      end
    RUBY
  end
end
