class Io::Tube::Purpose < Core::Io::Base
  set_model_for_input(::Tube::Purpose)
  set_json_root(:tube_purpose)

  define_attribute_and_json_mapping(%Q{
                     name  => name
  })
end
