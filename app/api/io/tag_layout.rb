class ::Io::TagLayout < ::Core::Io::Base
  set_model_for_input(::TagLayout)
  set_json_root(:tag_layout)
  set_eager_loading { |model| model.include_plate.include_tag_group }

  define_attribute_and_json_mapping(%Q{
         user <=> user
        plate <=> plate
    tag_group  => tag_group
    direction  => direction
  })
end
