# frozen_string_literal: true
class Io::Transfer::FromPlateToTubeByMultiplex < Core::Io::Base
  set_model_for_input(::Transfer::FromPlateToTubeByMultiplex)
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
