# frozen_string_literal: true
# Initialisation for the Rails plugin

require Rails.root.join('lib/informatics/lib/platform').to_s
directory = 'lib/informatics'
ActionController::Base.prepend_view_path File.join(directory, 'views/platform')
