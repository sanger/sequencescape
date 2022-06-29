# frozen_string_literal: true

# Import the routes to our external gemfiles, we'll subsequently use these in
# vite.config.ts to setup useful aliases
ViteRuby.env['FORMTASTIC_STYLESHEET_PATH'] = "#{Gem.loaded_specs['formtastic'].full_gem_path}/app/assets/stylesheets"
