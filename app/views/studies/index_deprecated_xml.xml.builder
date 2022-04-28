# frozen_string_literal: true
xml.instruct!
xml.studies(api_data) do
  @studies
    .with_user_included
    .with_related_users_included
    .includes(properties: :definition)
    .find_each do |study|
      xml.study do
        xml.id study.id
        xml.name study.name
        xml.active study.active?
        xml.user_id study.user_id
        unless study.followers.empty?
          xml.followers do
            study.followers.each do |f|
              xml.follower do
                xml.email f.email
                xml.name f.name
                xml.login f.login
                xml.id f.id
              end
            end
          end
        end
        xml.comment!('Family has been deprecated')
        xml.family_id ''
        xml.created_at study.created_at
        xml.updated_at study.updated_at
        xml.descriptors do
          study.study_metadata.attribute_value_pairs.each do |attribute, _name|
            xml.descriptor do
              xml.name attribute.to_field_info.display_name
              xml.value value
            end
          end
        end
      end
    end
end
