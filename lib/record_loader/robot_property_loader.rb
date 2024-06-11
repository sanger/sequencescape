# frozen_string_literal: true

# RecordLoader handles automatic population and updating of database records
# across different environments
# @see https://rubydoc.info/github/sanger/record_loader/
module RecordLoader
  # Creates the specified robot properties if they are not present
  class RobotPropertyLoader < ApplicationRecordLoader
    config_folder 'robot_properties'

    def create_or_update!(name, options)
      # find the robot by name
      r = Robot.find_by(name:)
      return if r.blank?

      # find or create each property
      options['properties'].each do |property_options|
        property_options['robot_id'] = r.id
        RobotProperty.create_with(property_options).find_or_create_by!(robot_id: r.id, key: property_options['key'])
      end
    end
  end
end
