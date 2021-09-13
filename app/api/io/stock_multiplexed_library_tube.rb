# frozen_string_literal: true
# Controls API V1 IO for StockMultiplexedLibraryTube
class Io::StockMultiplexedLibraryTube < Io::Tube
  set_model_for_input(::StockMultiplexedLibraryTube)
  set_json_root(:tube)

  define_attribute_and_json_mapping(
    '
                    sibling_tubes => sibling_tubes
  '
  )
end
