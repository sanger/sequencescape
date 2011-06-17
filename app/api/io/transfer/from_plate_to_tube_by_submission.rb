class ::Io::Transfer::FromPlateToTubeBySubmission < ::Core::Io::Base
  set_model_for_input(::Transfer::FromPlateToTubeBySubmission)
  set_json_root(:transfer)

  define_attribute_and_json_mapping(%Q{
          source <=> source
       transfers  => transfers
  })
end

