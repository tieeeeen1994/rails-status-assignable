# frozen_string_literal: true

module ActiveRecord::Associations::Builder # rubocop:disable Style/ClassAndModuleChildren
  class Association
    prepend StatusAssignable::Association
  end
end
