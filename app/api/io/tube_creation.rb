class ::Io::TubeCreation < ::Core::Io::Base
  set_model_for_input(::TubeCreation)
  set_json_root(:tube_creation)
  set_eager_loading { |model| model.include_parent }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
  })
end
