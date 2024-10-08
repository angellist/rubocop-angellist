# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::SidekiqDontUseKeywordArguments, :config do
  let(:config) { RuboCop::Config.new }

  it 'does not register an offense when using `#good_method`' do
    expect_no_offenses(<<~RUBY)
      good_method
    RUBY
  end
end
