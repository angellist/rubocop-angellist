# frozen_string_literal: true
# typed: true

require 'lint_roller'

module RuboCop
  module Angellist
    class Plugin < LintRoller::Plugin
      extend T::Sig

      sig { returns(LintRoller::About) }
      def about
        LintRoller::About.new(
          name: 'rubocop-angellist',
          version: VERSION,
          homepage: 'https://github.com/angellist/rubocop-angellist',
          description: 'Angellist\'s very own Alex Murphy. Part Man. Part Machine. All Cop.',
        )
      end

      sig { params(context: LintRoller::Context).returns(T::Boolean) }
      def supported?(context)
        context.engine == :rubocop
      end

      sig { params(_context: LintRoller::Context).returns(LintRoller::Rules) }
      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml'),
        )
      end
    end
  end
end
