# Included in {Robot}
# The intent of this file was to provide methods specific to the V1 API
module ModelExtensions::Robot
  def json_for_properties
    Hash[robot_properties.map { |prop| [prop.key, prop.value] }]
  end

  private
end
