class Io::Asset < Core::Io::Base
  set_model_for_input(::Asset)
  set_json_root(:asset)
  set_eager_loading { |model| model.include_barcode_prefix }

  define_attribute_and_json_mapping(%Q{
                         name  => name
                     qc_state  => qc_state
                      barcode  => barcode.number
        barcode_prefix.prefix  => barcode.prefix
      two_dimensional_barcode  => barcode.two_dimensional
                ean13_barcode  => barcode.ean13
                 barcode_type  => barcode.type
  })
end
