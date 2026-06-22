# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Sets both control and control_type fields on the sample
    class ControlType
      include Base

      validate :check_control_type_matches_enum, if: :value_present?

      def update(_attributes = {})
        return unless valid?

        if value.present?
          sample.control = true
          sample.control_type = value
        else
          sample.control = false
          sample.control_type = nil
        end
      end

      def check_control_type_matches_enum
        return if value.blank? || Sample.control_types.include?(value)

        errors.add(:base, "the control type #{value} was not recognised.")
      end
    end
  end
end
