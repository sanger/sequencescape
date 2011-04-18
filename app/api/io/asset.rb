class Io::Asset < Core::Io::Base
  set_model_for_input(::Asset)
  set_json_root(:asset)
  set_eager_loading { |model| model.include_barcode_prefix }
  
  define_attribute_and_json_mapping(%Q{
                         name  => name
                      barcode  => barcode
                     qc_state  => qc_state
        barcode_prefix.prefix  => barcode_prefix
      two_dimensional_barcode  => two_dimensional_barcode
  })
end
