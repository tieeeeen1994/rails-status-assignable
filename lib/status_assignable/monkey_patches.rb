# frozen_string_literal: true

require_relative 'monkey_patches/association'

module StatusAssignable
  # Rails reloader hook to apply monkey patches.
  module MonkeyPatches
    Rails.application.reloader.to_prepare do
      ActiveRecord::Associations::Builder::Association
        .singleton_class.prepend StatusAssignable::MonkeyPatches::Association
    end
  end
end
