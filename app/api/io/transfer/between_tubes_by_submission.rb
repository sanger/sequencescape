# frozen_string_literal: true
class Io::Transfer::BetweenTubesBySubmission < ::Core::Io::Base
  set_model_for_input(::Transfer::BetweenTubesBySubmission)
  set_json_root(:transfer)

  #  set_eager_loading { |model| model.include_source.include_destination }

  define_attribute_and_json_mapping(
    '
           user <=> user
         source <=> source
    destination  => destination
  '
  )
end
