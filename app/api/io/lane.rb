class Io::Lane < Io::Asset
  set_model_for_input(::Lane)
  set_json_root(:lane)
  #set_eager_loading { |model| model.include_barcode_prefix }

  define_attribute_and_json_mapping(%Q{
           external_release  => external_release
  })
end
