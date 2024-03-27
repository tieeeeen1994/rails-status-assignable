# frozen_string_literal: true

require_relative '../../status_assignable/association'

module ActiveRecord::Associations::Builder # rubocop:disable Style/ClassAndModuleChildren
  class Association
    prepend StatusAssignable::Association
  end
end
