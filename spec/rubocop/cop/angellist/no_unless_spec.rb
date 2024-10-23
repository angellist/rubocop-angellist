# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::NoUnless, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when unless is used' do
    expect_offense(<<~RUBY)
      return unless condition?
      ^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
    RUBY
  end

  context 'when autocorrecting offenses' do
    it 'swaps booleans for their opposites' do
      expect_offense(<<~RUBY)
        return unless true
        ^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless false
        ^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if false
        return if true
      RUBY
    end

    it 'flips the negation on a named variable condition' do
      expect_offense(<<~RUBY)
        do_something unless conditional_variable
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        do_something unless !conditional_variable
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        do_something if !conditional_variable
        do_something if conditional_variable
      RUBY
    end

    it 'corrects unless when used with else' do
      expect_offense(<<~RUBY)
        unless conditional_variable
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
          do_something
        else
          do_something_else
        end
      RUBY

      expect_correction(<<~RUBY)
        if !conditional_variable
          do_something
        else
          do_something_else
        end
      RUBY
    end

    it 'flips the sign when a locally defined method is called' do
      expect_offense(<<~RUBY)
        return unless condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless !condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if !condition?
        return if condition?
      RUBY
    end

    it 'flips the sign when a methd on another class or module is called' do
      expect_offense(<<~RUBY)
        return unless Test.condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless !Test.condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if !Test.condition?
        return if Test.condition?
      RUBY
    end

    it 'applies DeMorgan\'s law to handle and, or, and nested conditions' do
      expect_offense(<<~RUBY)
        return unless Test.condition? && other_condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless Test.condition? || other_condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless Test.condition? && !other_condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless !Test.condition? || other_condition?
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless !Test.condition? || (!other_condition? && condition_variable)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless !Test.condition? && (other_condition? || !condition_variable)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if !Test.condition? || !other_condition?
        return if !Test.condition? && !other_condition?
        return if !Test.condition? || other_condition?
        return if Test.condition? && !other_condition?
        return if Test.condition? && (other_condition? || !condition_variable)
        return if Test.condition? || (!other_condition? && condition_variable)
      RUBY
    end

    it 'corrects unless defined? correctly' do
      expect_offense(<<~RUBY)
        return unless defined?(SomeModule)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if !defined?(SomeModule)
      RUBY
    end

    it 'flips inequality operators' do
      expect_offense(<<~RUBY)
        return unless x < y
        ^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless x <= y
        ^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless x > y
        ^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless x >= y
        ^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless x == y
        ^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
        return unless x != y
        ^^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if x >= y
        return if x > y
        return if x <= y
        return if x < y
        return if x != y
        return if x == y
      RUBY
    end

    it 'corrects assignments' do
      expect_offense(<<~RUBY)
        return unless x = y
        ^^^^^^^^^^^^^^^^^^^ Angellist/NoUnless: Use `if !condition` instead of `unless condition`.
      RUBY

      expect_correction(<<~RUBY)
        return if !(x = y)
      RUBY
    end
  end
end
