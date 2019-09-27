# Controls API V1 IO for {::ExtractionAttribute}
class ::Io::ExtractionAttribute < ::Core::Io::Base
  set_model_for_input(::ExtractionAttribute)
  set_json_root(:extraction_attribute)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
                       created_by <=> created_by
                    attributes_update <=> attributes_update
  ")
end
