# Controls API V1 IO for {::Pipeline}
class ::Io::Pipeline < ::Core::Io::Base
  set_model_for_input(::Pipeline)
  set_json_root(:pipeline)

  define_attribute_and_json_mapping("
                    name  => name
  ")
end
