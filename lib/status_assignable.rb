# frozen_string_literal: true

require_relative 'status_assignable/version'

# Allows for soft deletion of records.
# Include this module in your model to enable soft deletion.
# e.g:
#   class User < ApplicationRecord
#     include StatusAssignable
#   end
# This requires a status column with type integer to be present in the model's table.
module StatusAssignable
  extend ActiveSupport::Concern

  DEFAULT_STATUSES = { deleted: 0, active: 1, inactive: 2 }.freeze

  def self.status_dictionary
    @status_dictionary || { deleted: 0, active: 1, inactive: 2 }
  end

  def self.clear_dictionary
    @status_dictionary = nil
  end

  # Allows adding custom statuses to the model's status enum.
  # @param [Hash<Symbol, Integer>] status_dictionary Custom statuses to add.
  # @return [Models::StatusAssignable] Itself.
  def self.[](status_dictionary)
    resulting_statuses = DEFAULT_STATUSES.merge(status_dictionary)
    raise ArgumentError, "Default statuses overridden. Don't do this." unless resulting_statuses >= DEFAULT_STATUSES
    unless resulting_statuses.values.uniq.length == resulting_statuses.values.length
      raise ArgumentError, 'Status values must be unique.'
    end

    @status_dictionary = resulting_statuses
    self
  end

  included do # rubocop:disable Metrics/BlockLength
    define_callbacks :soft_destroy, scope: %i[kind name]
    enum status: Models::StatusAssignable.status_dictionary
    Models::StatusAssignable.clear_dictionary

    # Updates the status of the record directly to the database.
    # @return [self, Boolean] Itself if true or false if failed.
    def soft_delete
      result = transaction do
        archive_associations
        update_columns(archive_params)
      end
      result ? self : false
    end

    # Updates the record through back to back callbacks.
    # @return [<Type>] Itself if true or false if failed.
    def soft_destroy
      result = transaction do
        run_callbacks :soft_destroy do
          archive_associations
          set_paper_trail_event
          update(archive_params)
        end
      end
      result ? self : false
    end

    alias_method :archive, :soft_destroy

    private

    def paper_trail_enabled?
      defined?(PaperTrail) && PaperTrail.request.enabled_for_model?(self.class)
    end

    def set_paper_trail_event
      # This uses PaperTrail's on_update method instead of destroy.
      # However, the code sets it to destroy event due to the nature of the library.
      self.paper_trail_event = 'destroy' if paper_trail_enabled?
    end

    def archive_params
      @archive_params ||= { status: 'deleted', updated_at: Time.current }
    end

    def archivable_associations
      @archivable_associations ||= self.class.reflect_on_all_associations.select do |association|
        association.options[:archive]
      end
    end

    def archive_associations
      archivable_associations.each do |association|
        archive_procedure = association.options[:archive]
        query = send(association.name)
        case archive_procedure
        when :callbacks
          query.respond_to?(:each) ? query.each(&:soft_destroy) : query.soft_destroy
        when :assign
          query.respond_to?(:update_all) ? query.update_all(archive_params) : query.update_columns(archive_params)
        end
      end
    end
  end
end
