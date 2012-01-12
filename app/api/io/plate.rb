class Io::Plate < Io::Asset
  set_model_for_input(::Plate)
  set_json_root(:plate)
  set_eager_loading { |model| model.include_plate_metadata.include_plate_purpose }

  define_attribute_and_json_mapping(%Q{
                                           size <=> size
                             plate_purpose.name  => plate_purpose.name

                                          state  => state
                                      iteration  => iteration
                                          pools  => pools

                               stock_plate.uuid  => stock_plate.uuid
                            stock_plate.barcode  => stock_plate.barcode.number
              stock_plate.barcode_prefix.prefix  => stock_plate.barcode.prefix
            stock_plate.two_dimensional_barcode  => stock_plate.barcode.two_dimensional
                      stock_plate.ean13_barcode  => stock_plate.barcode.ean13
                       stock_plate.barcode_type  => stock_plate.barcode.type
  })
end
