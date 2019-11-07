# Controls API V1 IO for {::Lane}
class Io::Lane < Io::Asset
  set_model_for_input(::Lane)
  set_json_root(:lane)
  define_attribute_and_json_mapping("
           external_release  => external_release
  ")
end
