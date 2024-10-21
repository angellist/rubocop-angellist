# typed: strict
# frozen_string_literal: true

require 'rubocop'

require_relative 'rubocop/angellist'
require_relative 'rubocop/angellist/version'
require_relative 'rubocop/angellist/inject'

RuboCop::Angellist::Inject.defaults!

require_relative 'rubocop/cop/angellist_cops'
