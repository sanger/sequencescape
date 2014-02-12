class Io::Robot < ::Core::Io::Base
  set_model_for_input(::Robot)
  set_json_root(:robot)

  define_attribute_and_json_mapping(%Q{
                               name => name
  })
end
