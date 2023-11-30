# frozen_string_literal: true
class ApiV2Generator < Rails::Generators::NamedBase
  source_root File.expand_path('../templates', __FILE__)

  def create_directories
    directory '.', './'
  end

  def add_routes
    json_route "jsonapi_resources :#{underscores}"
  end

  private

  def camelcase
    name.camelcase
  end

  def camelcases
    name.camelcase.pluralize
  end

  def underscore
    name.underscore
  end

  def underscores
    underscore.pluralize
  end

  def parameterized
    name.underscore.pluralize
  end

  def key_formatted
    name.underscore.pluralize
  end

  def json_route(routing_code)
    log :route, routing_code
    sentinel = /    namespace :v2 do\s*\n/m

    in_root do
      inject_into_file 'config/routes.rb', "      #{routing_code}\n", after: sentinel, verbose: false, force: false
    end
  end
end
