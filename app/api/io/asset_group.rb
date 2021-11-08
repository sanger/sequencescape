# frozen_string_literal: true
# Controls API V1 IO for {::AssetGroup}
class Io::AssetGroup < ::Core::Io::Base
  set_model_for_input(::AssetGroup)
  set_json_root(:asset_group)
  set_eager_loading { |model| model.include_study.include_assets }

  define_attribute_and_json_mapping(
    '
          name  => name
    study.name  => study.name
  '
  )
end
