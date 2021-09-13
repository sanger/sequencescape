# frozen_string_literal: true
# Controls API V1 IO for Purpose
class Io::Purpose < Core::Io::Base
  set_model_for_input(::Purpose)
  set_json_root(:purpose)

  define_attribute_and_json_mapping(
    '
                     name  => name
  '
  )
end
