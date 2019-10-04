# Controls API V1 IO for {::Tag2LayoutTemplate}
class ::Io::Tag2LayoutTemplate < ::Core::Io::Base
  set_model_for_input(::Tag2LayoutTemplate)
  set_json_root(:tag2_layout_template)
  set_eager_loading(&:include_tag) # TODO: uncomment and add any named_scopes that do includes you need

  define_attribute_and_json_mapping("
                 name  => name

              tag.name  => tag.name
            tag.map_id  => tag.identifier
             tag.oligo  => tag.oligo
    tag.tag_group.name  => tag.group
  ")
end
