class ::Io::BulkTransfer < ::Core::Io::Base
  set_model_for_input(::BulkTransfer)
  set_json_root(:bulk_transfer)

  define_attribute_and_json_mapping(%Q{
           user <=> user
well_transfers  <=  well_transfers
  })
end
