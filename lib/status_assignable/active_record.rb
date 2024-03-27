# frozen_string_literal: true

module StatusAssignable
  module ActiveRecord # rubocop:disable Style/Documentation
    def has_assignable_status # rubocop:disable Naming/PredicateName
      include StatusAssignable
    end
  end
end
