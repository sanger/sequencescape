module SampleManifestExcel
  module SpecialisedField
    ##
    # A required value which needs to be converted to an integer.
    # Updated in the aliquot.
    class InsertSizeFrom
      include Base
      include ValueRequired
      include ValueToInteger

      validates_numericality_of :value, greater_than: 0

      def update(attributes = {})
        if valid? && attributes[:aliquot].present?
          attributes[:aliquot].insert_size_from = value
        end
      end
    end
  end
end
