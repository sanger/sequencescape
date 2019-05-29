# Controls API V1 IO for PlateTemplate
class Io::PlateTemplate < Io::Asset
  set_model_for_input(::PlateTemplate)
  set_json_root(:plate_template)

  define_attribute_and_json_mapping("
                                           size <=> size
                                           name <=> name
  ")
end
