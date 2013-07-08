class ::Io::TubeFromTubeCreation < ::Core::Io::Base
  set_model_for_input(::TubeFromTubeCreation)
  set_json_root(:tube_from_tube_creation)

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
  })
end
