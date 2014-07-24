class Io::PlateTemplate < Io::Asset
  set_model_for_input(::PlateTemplate)
  set_json_root(:plate_template)

  define_attribute_and_json_mapping(%Q{
                                           size <=> size
                                           name <=> name
  })
end
