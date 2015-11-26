# Initialisation for the Rails plugin

require "lib/informatics/lib/platform"
directory = "lib/informatics"
ActionController::Base.prepend_view_path File.join(directory, 'views/platform')
