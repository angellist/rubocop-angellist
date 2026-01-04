# typed: true
# frozen_string_literal: true

require_relative 'angellist/version'

# Monkey patch to avoid writing `extend T::Sig` in every class/module
class Module
  include T::Sig
end

module RuboCop
  module Angellist
  end
end
