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
      wip_files = []
      wip_files_path = Rails.root.join('config/default_records')
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
