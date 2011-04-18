# Initialisation for the Rails plugin

require "platform"
ActionController::Base.prepend_view_path File.join(directory, 'views/platform')
