# frozen_string_literal: true
# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified plate types if they are not present
  class FlowcellTypeLoader < ApplicationRecordLoader
    config_folder 'flowcell_types'

    def create_or_update!(requested_flowcell_type, options)
      FlowcellType.create_with(options).find_or_create_by!(requested_flowcell_type: requested_flowcell_type)
    end
  end
end