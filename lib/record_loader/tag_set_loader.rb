# frozen_string_literal: true

# This file was automatically generated via `rails g record_loader`

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified TagSet if they are not present
  class TagSetLoader < ApplicationRecordLoader
    config_folder 'tag_sets'

    def create_or_update!(name, options)
      TagSet.create_with(options).find_or_create_by!(name:)
    end
  end
end
