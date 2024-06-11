# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified tag group adapter types if they are not present
  class TagGroupAdapterTypeLoader < ApplicationRecordLoader
    config_folder 'tag_group_adapter_types'

    def create_or_update!(name, _options)
      TagGroup::AdapterType.find_or_create_by!(name:)
    end
  end
end
