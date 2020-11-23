module BroadcastEvent::Helpers
  module ExternalSubjects
    def subjects
      return [] unless properties && properties.has_key?(:subjects)

      @subjects ||= properties[:subjects].map do |prop|
        obj = OpenStruct.new(prop)
        BroadcastEvent::SubjectHelpers::Subject.new(obj.role_type, obj)
      end
    end
  end
end
