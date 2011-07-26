class Io::BaitLibrary < Core::Io::Base
  set_model_for_input(::BaitLibrary)
  set_json_root(:bait_library)

  define_attribute_and_json_mapping(%Q{
    bait_library_supplier.name  => supplier.name
           supplier_identifier  => supplier.identifier
                          name  => name
                target_species  => target.species
  })
end
