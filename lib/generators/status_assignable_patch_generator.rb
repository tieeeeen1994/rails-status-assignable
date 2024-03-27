# frozen_string_literal: true

# Generates a patch for Rails so that status assignable models can have their associations archived when soft deleted.
class StatusAssignablePatchGenerator < Rails::Generators::Base
  source_root File.expand_path('templates', __dir__)

  def create_patch_file
    template 'monkey_patch.rb.erb', File.join('config/initializers/status_assignable.rb')
  end
end
