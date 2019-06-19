# Controls API V1 IO for Asset
class Io::Asset < Core::Io::Base
  set_model_for_input(::Asset)
  set_json_root(:asset)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping("
                         name  => name
                     qc_state  => qc_state
  ")
end
