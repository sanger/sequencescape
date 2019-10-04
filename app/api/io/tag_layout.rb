# Controls API V1 IO for {::TagLayout}
class ::Io::TagLayout < ::Core::Io::Base
  set_model_for_input(::TagLayout)
  set_json_root(:tag_layout)
  set_eager_loading { |model| model.include_plate.include_tag_group }

  define_attribute_and_json_mapping("
    user <=> user
    plate <=> plate
    substitutions <=> substitutions
    tag_group <=> tag_group
    tag2_group <=> tag2_group
    direction <=> direction
    walking_by <=> walking_by
    initial_tag <=> initial_tag
  ")
end
