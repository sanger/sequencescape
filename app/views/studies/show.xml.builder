xml.instruct!
xml.study(api_data) do |study|
  study.id @study.id
  study.name @study.name
  study.active @study.active?
  study.user_id @study.user_id

  [ 'followers', 'managers', 'owners' ].each do |type_of_user|
    users, singular_user = @study.send(type_of_user), type_of_user.singularize
    study.tag!(type_of_user) do |users_tag|
      users.each do |user|
        users_tag.tag!(singular_user) do |user_tag|
          user_tag.login(user.login)
          user_tag.email(user.email)
          user_tag.name(user.name)
          user_tag.id(user.id)
        end
      end
    end unless users.empty?
  end

  xml.comment!("Family has been deprecated")
  study.family_id ""
  study.created_at @study.created_at
  study.updated_at @study.updated_at

  study.descriptors do |descriptors|
    @study.study_metadata.attribute_value_pairs.each do |attribute,value|
      descriptors.descriptor do |descriptor|
        descriptor.name(attribute.to_field_info.display_name)
        descriptor.value(value)
      end
    end

    @study.study_metadata.association_value_pairs.each do |attribute,value|
      descriptors.descriptor do |descriptor|
        descriptor.name(attribute.to_field_info.display_name)
        if (attribute.to_field_info.display_name == "Reference Genome") && (value.blank?)
          descriptor.value(nil)
        else 
          descriptor.value(value)
        end
      end
    end
  end  
end
