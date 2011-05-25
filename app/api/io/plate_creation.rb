class ::Io::PlateCreation < ::Core::Io::Base
  set_model_for_input(::PlateCreation)
  set_json_root(:plate_creation)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
                   user <=  user
                 parent <=  parent
    child_plate_purpose <=  child_plate_purpose
  })
end
