# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # A required value which needs to be converted to an integer.
    # Updated in the aliquot.
    class InsertSizeTo
      include Base
      include ValueRequired
      include ValueToInteger

      validates_numericality_of :value, greater_than: 0, message: "'insert size to' must be greater than 0"

      def update(_attributes = {})
        return unless valid? && aliquots.present?

        aliquots.each { |aliquot| aliquot.insert_size_to = value }
      end
    end
  end
end
