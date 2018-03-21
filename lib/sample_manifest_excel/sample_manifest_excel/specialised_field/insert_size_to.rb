module SampleManifestExcel
  module SpecialisedField
    ##
    # A required value which needs to be converted to an integer.
    # Updated in the aliquot.
    class InsertSizeTo
      include Base
      include ValueRequired
      include ValueToInteger

      validates_numericality_of :value, greater_than: 0, message: "'insert size to' must be greater than 0"

      def update(attributes = {})
        if valid? && attributes[:aliquot].present?
          attributes[:aliquot].insert_size_to = value
        end
      end
    end
  end
end
