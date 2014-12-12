class Io::AssetRackPurpose < Core::Io::Base

  set_model_for_input(::AssetRack::Purpose)

  set_json_root(:asset_rack_purpose)

  define_attribute_and_json_mapping(%Q{
                     name  => name
  })
end
