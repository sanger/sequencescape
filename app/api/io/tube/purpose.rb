# frozen_string_literal: true

# Controls API V1 IO for Tube
class Io::Tube::Purpose < Core::Io::Base
  set_model_for_input(::Tube::Purpose)
  set_json_root(:tube_purpose)

  define_attribute_and_json_mapping(
    '
    name  <=> name
    parent_purposes <= parents
    child_purposes <= children
    target_type <= target_type
    type <= type
  '
  )
end
