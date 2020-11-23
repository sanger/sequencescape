module BroadcastEvent::Helpers
  module ExternalSubjects
    def subjects
      return [] unless properties && properties.has_key?(:subjects)

      @subjects ||= build_subjects
    end

    def build_subjects
      properties[:subjects].map do |prop|
        obj = OpenStruct.new(prop)
        BroadcastEvent::SubjectHelpers::Subject.new(obj.role_type, obj)
      end      
    end

    def subjects_with_role_type(role_type)
      subjects.select{|sub| sub.role_type == role_type}
    end
  
    def has_subjects_with_role_type?(role_type)
      subjects_with_role_type(role_type).length > 0
    end
    
    def check_subject_role_type(property, role_type)
      unless has_subjects_with_role_type?(role_type)
        errors.add(property, 'not provided')
      end
    end
    
  end
end
