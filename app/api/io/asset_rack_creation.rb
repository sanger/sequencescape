class ::Io::AssetRackCreation < ::Core::Io::Base
  set_model_for_input(::AssetRackCreation)
  set_json_root(:asset_rack_creation)
  set_eager_loading { |model| model.include_parent.include_child }

  define_attribute_and_json_mapping(%Q{
                   user <=> user
                 parent <=> parent
          child_purpose <=> child_purpose
                  child  => child
  })
end
