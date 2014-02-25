class Io::Robot < ::Core::Io::Base
  set_model_for_input(::Robot)
  set_json_root(:robot)

  set_eager_loading { |model| model.include_properties }

  define_attribute_and_json_mapping(%Q{
                               name => name
                json_for_properties => robot_properties
  })
end
