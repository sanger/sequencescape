module ModelExtensions::Robot

  def json_for_properties
    Hash[robot_properties.map {|prop| [prop.key,prop.value] }]
  end

  private

end
