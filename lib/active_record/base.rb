# frozen_string_literal: true

require_relative '../status_assignable/active_record'
module ActiveRecord
  class Base # rubocop:disable Style/Documentation
    singleton_class.prepend StatusAssignable::ActiveRecord
  end
end
