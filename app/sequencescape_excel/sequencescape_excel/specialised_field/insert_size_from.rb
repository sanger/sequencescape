# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # A required value which needs to be converted to an integer.
    # Updated in the aliquot.
    class InsertSizeFrom
      include Base
      include ValueRequired
      include ValueToInteger

      validates_numericality_of :value, greater_than: 0, message: "'insert size from' must be greater than 0"

      def update(attributes = {})
        return unless valid? && attributes[:aliquot].present?

        aliquots.each do |aliquot|
          aliquot.insert_size_from = value
        end
      end
    end
  end
end
