class ::Io::TransferTemplate < ::Core::Io::Base
  set_model_for_input(::TransferTemplate)
  set_json_root(:transfer_template)

  define_attribute_and_json_mapping(%Q{
                   name  => name
              transfers  => transfers
  })
end
