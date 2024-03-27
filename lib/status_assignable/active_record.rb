# frozen_string_literal: true

module StatusAssignable
  # Integration with ActiveRecord so that the model can simply call has_assignable_status.
  module ActiveRecord
    def has_assignable_status(custom_statuses = nil) # rubocop:disable Naming/PredicateName
      if custom_statuses.nil?
        include StatusAssignable
      else
        include StatusAssignable[custom_statuses]
      end
    end
  end
end
