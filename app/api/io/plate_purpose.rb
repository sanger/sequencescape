class Io::PlatePurpose < Core::Io::Base
  set_model_for_input(::PlatePurpose)
  set_json_root(:plate_purpose)

  define_attribute_and_json_mapping(%Q{
                     name  => name
  })
end
