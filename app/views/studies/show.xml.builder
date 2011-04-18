xml.instruct!
xml.study(api_data) do |study|
  study.id @study.id
  study.name @study.name
  study.active @study.active?
  study.user_id @study.user_id

  unless @study.followers.empty?
    study.followers do |followers|
      @study.followers.each do |f|
        followers.follower do |follower|
          follower.login f.login
          follower.email f.email
          follower.name f.name
          follower.id f.id
        end
      end
    end
  end

  unless @study.managers.empty?
    study.managers do |managers|
      @study.managers.each do |m|
        managers.manager do |manager|
          manager.login m.login
          manager.email m.email
          manager.name m.name
          manager.id m.id
        end
      end
    end
  end

  unless @study.owners.empty?
    study.owners do |owners|
      @study.owners.each do |o|
        owners.owner do |owner|
          owner.login o.login
          owner.email o.email
          owner.name o.name
          owner.id o.id
        end
      end
    end
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
