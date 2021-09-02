# frozen_string_literal: true
# Controls API V1 IO for PlatePurpose
class Io::PlatePurpose < Core::Io::Base
  set_model_for_input(::PlatePurpose)
  set_json_root(:plate_purpose)

  define_attribute_and_json_mapping(
    '
    name <=> name
    lifespan <=> lifespan
    cherrypickable_target <=> cherrypickable_target
    stock_plate <=> stock_plate
    input_plate <= input_plate
    size <=> size
  '
  )
end
