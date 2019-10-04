# frozen_string_literal: true

# Controls API V1 IO for {::Labware}
class Io::Labware < Core::Io::Base
  set_model_for_input(::Labware)
  set_json_root(:asset)
  set_eager_loading { |model| model }

  define_attribute_and_json_mapping("
                         name  => name
  ")
end
