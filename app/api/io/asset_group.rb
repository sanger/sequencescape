class ::Io::AssetGroup < ::Core::Io::Base
  set_model_for_input(::AssetGroup)
  set_json_root(:asset_group)
  set_eager_loading { |model| model.include_study.include_assets }

  define_attribute_and_json_mapping(%Q{
          name  => name
    study.name  => study.name
  })
end
