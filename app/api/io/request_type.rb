# Controls API V1 IO for {::RequestType}
class ::Io::RequestType < ::Core::Io::Base
  set_model_for_input(::RequestType)
  set_json_root(:request_type)

  define_attribute_and_json_mapping("
    name => name
  ")
end
