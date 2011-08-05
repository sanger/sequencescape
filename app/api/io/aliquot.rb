class Io::Aliquot < Core::Io::Base
  set_model_for_input(::Aliquot)
  set_json_root(:aliquot)

  define_attribute_and_json_mapping(%Q{
                sample  => sample

              tag.name  => tag.name
            tag.map_id  => tag.identifier
             tag.oligo  => tag.oligo
    tag.tag_group.name  => tag.group

          bait_library  => bait_library

      insert_size.from  => insert_size.from
        insert_size.to  => insert_size.to
  })
end
