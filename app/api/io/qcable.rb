class Io::Qcable < Core::Io::Base
  set_model_for_input(::Qcable)
  set_json_root(:qcable)

  set_eager_loading { |model| model.include_asset }

  define_attribute_and_json_mapping(%Q{
       asset.barcode  => asset_barcode
               state  => state
  })
end
