class ::Io::PlateCreation < ::Core::Io::Base
  set_model_for_input(::PlateCreation)
  set_json_root(:plate_creation)
  set_eager_loading { |model| model.include_parent.include_child }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
                  child  => child
  })
end
