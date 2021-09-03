# frozen_string_literal: true
# Controls API V1 IO for QcDecision
class Io::QcDecision < Core::Io::Base
  set_model_for_input(::QcDecision)
  set_json_root(:qc_decision)

  define_attribute_and_json_mapping(
    '
                user <=> user
                 lot <=> lot
           decisions <= decisions
  '
  )
end
