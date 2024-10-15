# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified workflows if they are not present
  class WorkflowLoader < ApplicationRecordLoader
    config_folder 'workflows'

    def create_or_update!(name, options)
      Workflow.create_with(options).find_or_create_by!(name:)
    end
  end
end
