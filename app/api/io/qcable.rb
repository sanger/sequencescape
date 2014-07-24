class Io::Qcable < Core::Io::Base
  set_model_for_input(::Qcable)
  set_json_root(:qcable)

  set_eager_loading { |model| model.include_for_json }

  define_attribute_and_json_mapping(%Q{
                      state  => state
            stamp_qcable.bed => stamp_bed
                 stamp_index => stamp_index

              asset.barcode  => barcode.number
 asset.barcode_prefix.prefix => barcode.prefix
         asset.ean13_barcode => barcode.ean13
  })
end
