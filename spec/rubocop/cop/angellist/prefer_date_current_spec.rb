# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::PreferDateCurrent, :config do
  let(:config) { RuboCop::Config.new }

  # TODO: Write test code
  #
  # For example
  it 'registers an offense when using `Time.zone.today`' do
    expect_offense(<<~RUBY)
      Time.zone.today
      ^^^^^^^^^^^^^^^ Angellist/PreferDateCurrent: Use `Date.current` instead of `Time.zone.today`.
    RUBY
  end

  it 'does not register an offense when using `Date.current`' do
    expect_no_offenses(<<~RUBY)
      Date.current
    RUBY
  end
end
