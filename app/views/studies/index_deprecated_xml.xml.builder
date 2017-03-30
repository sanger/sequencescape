xml.instruct!
xml.studies(api_data) {
  @studies.with_user_included.with_related_users_included.includes(properties: :definition).find_each do |study|
    xml.study {
      xml.id study.id
      xml.name study.name
      xml.active study.active?
      xml.user_id study.user_id
      unless study.followers.empty?
        xml.followers {
          study.followers.each do |f|
            xml.follower {
              xml.email f.email
              xml.name f.name
              xml.login f.login
              xml.id f.id
            }
          end
        }
      end
      xml.comment!("Family has been deprecated")
      xml.family_id ""
      xml.created_at study.created_at
      xml.updated_at study.updated_at
      xml.descriptors {
        study.study_metadata.attribute_value_pairs.each do |attribute, name|
          xml.descriptor {
            xml.name  attribute.to_field_info.display_name
            xml.value value
          }
        end
      }
    }
  end
}
