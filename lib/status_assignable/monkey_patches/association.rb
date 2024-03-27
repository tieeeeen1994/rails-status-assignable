# frozen_string_literal: true

module StatusAssignable
  module MonkeyPatches
    # This will allow the model to allow custom :archive option to be valid.
    # The values accepted by the :archive option are :callbacks and :assign.
    module Association
      CUSTOM_VALID_OPTIONS = [:archive].freeze
      VALID_ARCHIVE_OPTIONS = %i[callbacks assign].freeze

      private

      def valid_options(options)
        super(options) + CUSTOM_VALID_OPTIONS
      end

      def define_callbacks(model, reflection)
        if (archive_option_value = reflection.options[:archive])
          check_archive_options(archive_option_value)
        end
        super(model, reflection)
      end

      def check_archive_options(archive_option_value)
        return if VALID_ARCHIVE_OPTIONS.include? archive_option_value

        message = "The :archive option must be one of #{VALID_ARCHIVE_OPTIONS}, but is :#{archive_option_value}"
        raise ArgumentError, message
      end
    end
  end
end
