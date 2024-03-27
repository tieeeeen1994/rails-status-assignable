# frozen_string_literal: true

module ActiveRecord
  class Base # rubocop:disable Style/Documentation
    singleton_class.prepend StatusAssignable::ActiveRecord
  end
end
