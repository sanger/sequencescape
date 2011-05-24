class ::Io::Transfer < ::Core::Io::Base
  set_model_for_input(::Transfer)
  set_json_root(:transfer)
  # set_eager_loading { |model| model }   # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping(%Q{
         source <=  source
    destination <=  destination
      transfers <=> transfers
  })
end
