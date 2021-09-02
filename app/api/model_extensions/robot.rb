# frozen_string_literal: true
# Included in {Robot}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Robot
  def json_for_properties
    robot_properties.map { |prop| [prop.key, prop.value] }.to_h
  end

  private
end
