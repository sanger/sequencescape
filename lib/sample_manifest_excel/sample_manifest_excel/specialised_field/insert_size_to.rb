module SampleManifestExcel
  module SpecialisedField
    class InsertSizeTo
      include Base
      include ValueRequired
      include ValueToInteger
      
      validates_numericality_of :value, greater_than: 0

      def update(aliquot: )
        if valid? && aliquot.present?
          aliquot.insert_size_to = value
          aliquot.save
        end
      end
    end
  end
end