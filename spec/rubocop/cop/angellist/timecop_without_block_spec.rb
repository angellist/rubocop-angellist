# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::TimecopWithoutBlock, :config do
  let(:config) { RuboCop::Config.new }

  context 'when using Timecop.freeze' do
    it 'registers an offense when called without a block' do
      expect_offense(<<~RUBY)
        Timecop.freeze(Time.now)
        ^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/TimecopWithoutBlock: Use the block form of `Timecop.freeze` instead of calling it without a block.
      RUBY
    end

    it 'registers an offense when called without arguments or block' do
      expect_offense(<<~RUBY)
        Timecop.freeze
        ^^^^^^^^^^^^^^ Angellist/TimecopWithoutBlock: Use the block form of `Timecop.freeze` instead of calling it without a block.
      RUBY
    end

    it 'does not register an offense when called with a block' do
      expect_no_offenses(<<~RUBY)
        Timecop.freeze(Time.now) do
          do_something
        end
      RUBY
    end

    it 'does not register an offense when called with a block and no arguments' do
      expect_no_offenses(<<~RUBY)
        Timecop.freeze do
          do_something
        end
      RUBY
    end
  end

  context 'when using Timecop.travel' do
    it 'registers an offense when called without a block' do
      expect_offense(<<~RUBY)
        Timecop.travel(1.day.from_now)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/TimecopWithoutBlock: Use the block form of `Timecop.travel` instead of calling it without a block.
      RUBY
    end

    it 'does not register an offense when called with a block' do
      expect_no_offenses(<<~RUBY)
        Timecop.travel(1.day.from_now) do
          do_something
        end
      RUBY
    end
  end

  context 'when using ::Timecop with top-level constant reference' do
    it 'registers an offense when called without a block' do
      expect_offense(<<~RUBY)
        ::Timecop.freeze(Time.now)
        ^^^^^^^^^^^^^^^^^^^^^^^^^^ Angellist/TimecopWithoutBlock: Use the block form of `Timecop.freeze` instead of calling it without a block.
      RUBY
    end

    it 'does not register an offense when called with a block' do
      expect_no_offenses(<<~RUBY)
        ::Timecop.freeze(Time.now) do
          do_something
        end
      RUBY
    end
  end

  context 'when using other Timecop methods' do
    it 'does not register an offense for Timecop.return' do
      expect_no_offenses(<<~RUBY)
        Timecop.return
      RUBY
    end

    it 'does not register an offense for Timecop.scale' do
      expect_no_offenses(<<~RUBY)
        Timecop.scale(100)
      RUBY
    end
  end

  context 'when freeze/travel is called on a different receiver' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        SomeOtherClass.freeze
      RUBY
    end
  end
end
