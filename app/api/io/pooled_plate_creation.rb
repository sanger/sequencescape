class ::Io::PooledPlateCreation < ::Core::Io::Base
  set_model_for_input(::PooledPlateCreation)
  set_json_root(:pooled_plate_creation)
  #set_eager_loading { |model| model.include_parents.include_child }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                parents <=  parents
          child_purpose <=> child_purpose
                  child  => child
  })
end
