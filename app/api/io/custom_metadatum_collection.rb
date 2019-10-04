# Controls API V1 IO for {::CustomMetadatumCollection}
class ::Io::CustomMetadatumCollection < ::Core::Io::Base
  set_model_for_input(::CustomMetadatumCollection)
  set_json_root(:custom_metadatum_collection)

  define_attribute_and_json_mapping("
             metadata <=> metadata
             user <= user
             asset <= asset
  ")
end
