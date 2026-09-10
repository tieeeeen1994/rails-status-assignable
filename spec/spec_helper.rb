# frozen_string_literal: true

require 'rails'
require 'active_support/core_ext/time'
require 'status_assignable'

RSpec.configure do |config|
  config.disable_monkey_patching!

  config.expect_with :rspec do |expectations|
    expectations.syntax = :expect
  end
end
