# frozen_string_literal: true

# Easily build new uat actions
# `rails generate uat_action` for more information
class UatActionGenerator < Rails::Generators::NamedBase
  source_root File.expand_path('templates', __dir__)

  class_option :description, type: :string, default: ''
  class_option :title, type: :string, default: ''

  def create_directories
    directory '.', './'
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

  def humanize
    underscore.humanize
  end

  def title
    options['title'].presence || humanize
  end

  def description
    options['description']
  end
end
