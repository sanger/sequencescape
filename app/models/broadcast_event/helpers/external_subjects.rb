# frozen_string_literal: true
module BroadcastEvent::Helpers
  # Provides support to define subjects that are referring to data stored
  # externally to Sequencescape. The subjects will be built from the
  # properties attribute, instead of the default BroadcastEvent procedure
  module ExternalSubjects
    def subjects
      return [] unless properties&.key?(:subjects)

      @subjects ||= build_subjects
    end

    def build_subjects
      properties[:subjects].map do |prop|
        obj = OpenStruct.new(prop) # rubocop:todo Style/OpenStructUse
        BroadcastEvent::SubjectHelpers::Subject.new(obj.role_type, obj)
      end
    end

    def subjects_with_role_type(role_type)
      subjects.select { |sub| sub.role_type == role_type }
    end

    def subjects_with_role_type?(role_type)
      subjects.any? { |sub| sub.role_type == role_type }
    end

    def check_subject_role_type(property, role_type)
      unless subjects_with_role_type?(role_type)
        errors.add(property, "is a required subject needed for the event '#{event_type}'")
      end
    end
  end
end
