# typed: false
# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Angellist::RedundantExtendTSig, :config do
  let(:config) { RuboCop::Config.new }

  it 'registers an offense when extend T::Sig is used in a class' do
    expect_offense(<<~RUBY)
      class Foo
        extend T::Sig
        ^^^^^^^^^^^^^ Angellist/RedundantExtendTSig: Unnecessary `extend T::Sig`. `sig` is already available without it.

        sig { returns(String) }
        def bar
          'baz'
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Foo
        sig { returns(String) }
        def bar
          'baz'
        end
      end
    RUBY
  end

  it 'registers an offense when extend T::Sig is used in a module' do
    expect_offense(<<~RUBY)
      module Foo
        extend T::Sig
        ^^^^^^^^^^^^^ Angellist/RedundantExtendTSig: Unnecessary `extend T::Sig`. `sig` is already available without it.
      end
    RUBY

    expect_correction(<<~RUBY)
      module Foo
      end
    RUBY
  end

  it 'registers an offense when extend T::Sig is used in class << self' do
    expect_offense(<<~RUBY)
      class Foo
        class << self
          extend T::Sig
          ^^^^^^^^^^^^^ Angellist/RedundantExtendTSig: Unnecessary `extend T::Sig`. `sig` is already available without it.

          sig { returns(String) }
          def bar
            'baz'
          end
        end
      end
    RUBY

    expect_correction(<<~RUBY)
      class Foo
        class << self
          sig { returns(String) }
          def bar
            'baz'
          end
        end
      end
    RUBY
  end

  it 'registers an offense when extend T::Sig is the only content with a blank line after' do
    expect_offense(<<~RUBY)
      class Foo
        extend T::Sig
        ^^^^^^^^^^^^^ Angellist/RedundantExtendTSig: Unnecessary `extend T::Sig`. `sig` is already available without it.

        include SomeModule
      end
    RUBY

    expect_correction(<<~RUBY)
      class Foo
        include SomeModule
      end
    RUBY
  end

  it 'does not register an offense when extend is used with something other than T::Sig' do
    expect_no_offenses(<<~RUBY)
      class Foo
        extend ActiveSupport::Concern
      end
    RUBY
  end

  it 'does not register an offense when there is no extend T::Sig' do
    expect_no_offenses(<<~RUBY)
      class Foo
        sig { returns(String) }
        def bar
          'baz'
        end
      end
    RUBY
  end
end
