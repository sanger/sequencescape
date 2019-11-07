# Controls API V1 IO for {::TagGroup}
class ::Io::TagGroup < ::Core::Io::Base
  set_model_for_input(::TagGroup)
  set_json_root(:tag_group)

  define_attribute_and_json_mapping("
            name  => name
    indexed_tags  => tags
  ")
end
