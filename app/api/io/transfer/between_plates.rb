class ::Io::Transfer::BetweenPlates < ::Core::Io::Base
  set_model_for_input(::Transfer::BetweenPlates)
  set_json_root(:transfer)

  define_attribute_and_json_mapping(%Q{
         source <=> source
    destination <=> destination
      transfers <=> transfers
  })
end
