# Controls API V1 IO for {::Asset}
# @note {Asset} is deprecated and has now been split into {Labware} and {Receptacle}
class Io::Asset < Core::Io::Base
  set_model_for_input(::Asset)
  set_json_root(:asset)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping("
                         name  => name
                     qc_state  => qc_state
  ")
end
