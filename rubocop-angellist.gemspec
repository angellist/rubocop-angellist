# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require_relative 'lib/rubocop/angellist/version'

Gem::Specification.new do |s|
  s.platform    = Gem::Platform::RUBY
  s.version     = RuboCop::Angellist::VERSION
  s.name        = 'rubocop-angellist'
  s.summary     = 'Part Man. Part Machine. All Cop.'

  s.author   = 'AngelList'
  s.email    = 'alex.stathis@angellist.com'
  s.homepage = 'https://www.github.com/angellist/rubocop-angellist'

  s.files = Dir['rubocop.yml', 'config/**/*', 'lib/**/*', 'README.md']

  s.required_ruby_version = '>= 3.3'

  s.add_dependency('rubocop', '~> 1')
  s.add_dependency('rubocop-shopify')
  s.add_dependency('rubocop-graphql')
  s.add_dependency('rubocop-performance')
  s.add_dependency('rubocop-sorbet')
  s.add_dependency('rubocop-rails')
  s.add_dependency('rubocop-rake')
  s.add_dependency('rubocop-rspec')
  s.add_dependency('rubocop-thread_safety')
end
