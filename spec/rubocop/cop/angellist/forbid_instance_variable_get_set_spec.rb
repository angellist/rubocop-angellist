# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::AngelList::ForbidInstanceVariableGetSet, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using instance_variable_get' do
    expect_offense(<<~RUBY)
      object.instance_variable_get(:@foo)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AngelList/ForbidInstanceVariableGetSet: Avoid using `instance_variable_get` or `instance_variable_set`. Prefer using public getters/setters.
    RUBY
  end

  it 'registers an offense when using instance_variable_set' do
    expect_offense(<<~RUBY)
      object.instance_variable_set(:@foo, value)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AngelList/ForbidInstanceVariableGetSet: Avoid using `instance_variable_get` or `instance_variable_set`. Prefer using public getters/setters.
    RUBY
  end

  it 'does not register an offense when using regular getters' do
    expect_no_offenses(<<~RUBY)
      object.foo
    RUBY
  end

  it 'does not register an offense when using regular setters' do
    expect_no_offenses(<<~RUBY)
      object.foo = value
    RUBY
  end

  it 'registers an offense when using instance_variable_get with string argument' do
    expect_offense(<<~RUBY)
      object.instance_variable_get("@foo")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AngelList/ForbidInstanceVariableGetSet: Avoid using `instance_variable_get` or `instance_variable_set`. Prefer using public getters/setters.
    RUBY
  end

  it 'registers an offense when using instance_variable_set with string argument' do
    expect_offense(<<~RUBY)
      object.instance_variable_set("@foo", value)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ AngelList/ForbidInstanceVariableGetSet: Avoid using `instance_variable_get` or `instance_variable_set`. Prefer using public getters/setters.
    RUBY
  end
end 