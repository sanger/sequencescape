# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    # Specialised field for priority
    class Priority
      include Base
      include ValueToInteger

      validate :check_priority

      def update(_attributes = {})
        return unless valid?

        sample.priority = value if value.present?
      end

      private

      def check_priority
        return if value.blank?
        return if Sample.priorities.value?(value)

        errors.add(:base, "the priority #{value} was not recognised.")
      end
    end
  end
end
