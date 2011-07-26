class ::Io::Transfer::FromPlateToTube < ::Core::Io::Base
  set_model_for_input(::Transfer::FromPlateToTube)
  set_json_root(:transfer)

  define_attribute_and_json_mapping(%Q{
           user <=> user
         source <=> source
    destination <=> destination
      transfers <=> transfers
  })
end

