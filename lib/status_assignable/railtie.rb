# frozen_string_literal: true

require_relative 'association'
require_relative 'active_record'

module StatusAssignable
  # Rails integration for the Status Assignable gem.
  class Railtie < Rails::Railtie
    initializer 'status_assignable.active_record' do |app|
      app.reloader.to_prepare do
        ::ActiveRecord::Associations::Builder::Association.singleton_class.prepend Association
        ::ActiveRecord::Base.singleton_class.prepend ActiveRecord
      end
    end
  end
end
