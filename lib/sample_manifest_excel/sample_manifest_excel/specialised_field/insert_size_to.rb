module SampleManifestExcel
  module SpecialisedField
    class InsertSizeTo
      include Base
      include ValueRequired
      
      include ValueToInteger
      validates_numericality_of :value, greater_than: 0
    end
  end
end