class ::Io::Transfer::BetweenPlatesBySubmission < ::Core::Io::Base
  set_model_for_input(::Transfer::BetweenPlatesBySubmission)
  set_json_root(:transfer)

  define_attribute_and_json_mapping(%Q{
         source <=> source
    destination <=> destination
      transfers  => transfers
  })
end
