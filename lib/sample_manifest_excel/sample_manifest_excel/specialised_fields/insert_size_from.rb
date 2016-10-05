module SampleManifestExcel
  module SpecialisedFields
    class InsertSizeFrom < Base
      validates_presence_of :value
      validates_numericality_of :value, greater_than: 0
    end
  end
end