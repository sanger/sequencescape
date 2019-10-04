# Controls API V1 IO for {::Search}
class ::Io::Search < ::Core::Io::Base
  set_json_root(:search)

  define_attribute_and_json_mapping("
    name  => name
  ")
end
