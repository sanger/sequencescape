# frozen_string_literal: true
class ::Io::Transfer::FromPlateToTubeBySubmission < ::Core::Io::Base # rubocop:todo Style/Documentation
  set_model_for_input(::Transfer::FromPlateToTubeBySubmission)
  set_json_root(:transfer)
  set_eager_loading { |model| model.include_source.include_transfers }

  define_attribute_and_json_mapping(
    '
            user <=> user
          source <=> source
       transfers  => transfers
  '
  )
end
