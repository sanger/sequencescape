# Controls API V1 IO for {::Transfer}
class ::Io::Transfer < ::Core::Io::Base
  set_model_for_input(::Transfer)
  set_json_root(:transfer)

  define_attribute_and_json_mapping("
           user <=> user
         source <=> source
  ")
end
