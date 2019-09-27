# Controls API V1 IO for {::Tag2Layout}
class ::Io::Tag2Layout < ::Core::Io::Base
  set_model_for_input(::Tag2Layout)
  set_json_root(:tag2_layout)
  set_eager_loading { |model| model.include_plate.include_tag }

  define_attribute_and_json_mapping("
                   user <=> user
                  plate <=> plate
  target_well_locations <=> target_well_locations
                 source <=> source

               tag.name  => tag.name
             tag.map_id  => tag.identifier
              tag.oligo  => tag.oligo
     tag.tag_group.name  => tag.group
  ")
end
