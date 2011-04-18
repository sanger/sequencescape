class Io::Plate < Io::Asset
  set_model_for_input(::Plate)
  set_json_root(:plate)
  set_eager_loading { |model| model.include_plate_purpose }

  define_attribute_and_json_mapping(%Q{
                                    size  => size
                      plate_purpose.name  => plate_purpose.name
                           ean13_barcode  => ean13_barcode
                                   wells  => wells
  })
end
