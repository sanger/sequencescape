# Controls API V1 IO for {::Aliquot}
class Io::Aliquot < Core::Io::Base
  set_model_for_input(::Aliquot)
  set_json_root(:aliquot)

  PRELOADS = [
    :bait_library,
    :primer_panel,
    {
      tag: :tag_group,
      tag2: :tag_group,
      sample: [
        :study_reference_genome,
        :uuid_object,
        { sample_metadata: :reference_genome }
      ]
    }
  ].freeze

  define_attribute_and_json_mapping("
                sample  => sample

              tag.name  => tag.name
            tag.map_id  => tag.identifier
             tag.oligo  => tag.oligo
    tag.tag_group.name  => tag.group

              tag2.name  => tag2.name
            tag2.map_id  => tag2.identifier
             tag2.oligo  => tag2.oligo
    tag2.tag_group.name  => tag2.group

          bait_library  => bait_library

      insert_size.from  => insert_size.from
        insert_size.to  => insert_size.to

             suboptimal => suboptimal
  ")
end
