# frozen_string_literal: true
# Controls API V1 IO for {::TagLayoutTemplate}
class Io::TagLayoutTemplate < Core::Io::Base
  set_model_for_input(::TagLayoutTemplate)
  set_json_root(:tag_layout_template)
  set_eager_loading { |model| model.include_tags.enabled_only }

  define_attribute_and_json_mapping(
    '
    name  => name
    tag_group  => tag_group
    tag2_group  => tag2_group
    direction  => direction
    walking_by  => walking_by
  '
  )
end
