# Controls API V1 IO for {::Well}
class ::Io::Well < ::Core::Io::Base
  set_model_for_input(::Well)
  set_json_root(:well)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
              state  => state
    map.description  => location
           aliquots  => aliquots
  ")
end
