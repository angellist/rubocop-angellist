# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) if !$LOAD_PATH.include?(lib)

require_relative 'lib/rubocop/angellist/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.version     = RuboCop::Angellist::VERSION
  s.name        = 'rubocop-angellist'
  s.summary     = 'Part Man. Part Machine. All Cop.'

  s.author   = 'AngelList'
  s.email    = 'alex.stathis@angellist.com'
  s.homepage = 'https://www.github.com/angellist/rubocop-angellist'
  s.metadata = {
    'default_lint_roller_plugin' => 'RuboCop::Angellist::Plugin',
  }

  s.files = Dir['rubocop.yml', 'config/**/*', 'lib/**/*', 'README.md']

  s.required_ruby_version = '>= 3.3'

  s.add_dependency('lint_roller')
  s.add_dependency('rubocop', '>= 1.72.0')
  s.add_dependency('rubocop-graphql', '>= 1.5.5')
  s.add_dependency('rubocop-performance', '>= 1.25.0')
  s.add_dependency('rubocop-rails', '>= 2.30.0')
  s.add_dependency('rubocop-rake', '>= 0.7.1')
  s.add_dependency('rubocop-rspec', '>= 3.5.0')
  s.add_dependency('rubocop-shopify')
  s.add_dependency('rubocop-sorbet', '>= 0.10.0')
  s.add_dependency('rubocop-thread_safety', '>= 0.7.2')
  s.add_dependency('sorbet-runtime')
end
