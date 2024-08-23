# frozen_string_literal: true
require 'find'

# This file was automatically generated by `rails g record_loader`
module RecordLoader
  # This forms the standard base class for record loaders in your
  # application, allowing for easy configuration.
  # @see https://rubydoc.info/github/sanger/record_loader/
  class ApplicationRecordLoader < RecordLoader::Base
    # Uses the standard RailsAdapter
    # @see https://rubydoc.info/github/sanger/record_loader/RecordLoader/Adapter
    adapter RecordLoader::Adapter::Rails.new

    def wip_list
      # return a list of WIP files name as features if deploy_wip_pipelines is set to true, or return empty list
      deploy_wip_pipelines = Rails.application.config.try(:deploy_wip_pipelines) || false
      return [] unless deploy_wip_pipelines

      wip_files = []
      wip_files_path = @path
      Find.find(wip_files_path) do |path|
        if path.match?(/\wip\.yml$/)
          file_name = File.basename(path, '.wip.yml')
          wip_files << file_name
        end
      end
      wip_files
    end
  end
end
