# frozen_string_literal: true

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified robots if they are not present
  class RobotLoader < ApplicationRecordLoader
    config_folder 'robots'

    def create_or_update!(name, options)
      Robot.create_with(options).find_or_create_by!(name:)
    end
  end
end
