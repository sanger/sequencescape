module SampleManifestExcel
  module SpecialisedField
    class InsertSizeFrom
      include Base
      include ValueRequired
      include ValueToInteger
      
      validates_numericality_of :value, greater_than: 0

      def update(aliquot: )
        if valid? && aliquot.present?
          aliquot.insert_size_from = value
          aliquot.save
        end
      end
    end
  end
end