# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::PreferWhereContains, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when using `@>` in a .where string' do
    expect_offense(<<~RUBY)
      Model.where("tags @> ARRAY[?]", "ruby")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/PreferWhereContains: Use `.where.contains(column: value)` instead of literal `@>` SQL in `.where`.
    RUBY
  end

  it 'registers an offense for jsonb containment with `@>`' do
    expect_offense(<<~RUBY)
      Model.where("data @> ?::jsonb", value)
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/PreferWhereContains: Use `.where.contains(column: value)` instead of literal `@>` SQL in `.where`.
    RUBY
  end

  it 'registers an offense for inline `@>` SQL without bind params' do
    expect_offense(<<~RUBY)
      scope.where("column @> ARRAY['value']")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/PreferWhereContains: Use `.where.contains(column: value)` instead of literal `@>` SQL in `.where`.
    RUBY
  end

  it 'registers an offense for `@>` in interpolated strings' do
    expect_offense(<<~'RUBY')
      Model.where("tags @> ARRAY[#{value}]")
      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/PreferWhereContains: Use `.where.contains(column: value)` instead of literal `@>` SQL in `.where`.
    RUBY
  end

  it 'does not register an offense when using .where.contains' do
    expect_no_offenses(<<~RUBY)
      Model.where.contains(tags: ["ruby"])
    RUBY
  end

  it 'does not register an offense for .where with hash conditions' do
    expect_no_offenses(<<~RUBY)
      Model.where(name: "test")
    RUBY
  end

  it 'does not register an offense for .where with non-@> SQL' do
    expect_no_offenses(<<~RUBY)
      Model.where("name = ?", "test")
    RUBY
  end

  it 'does not register an offense for `@>` outside of .where' do
    expect_no_offenses(<<~RUBY)
      execute("SELECT * FROM t WHERE tags @> ARRAY['ruby']")
    RUBY
  end
end
