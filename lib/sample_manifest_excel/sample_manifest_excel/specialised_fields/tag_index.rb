module SampleManifestExcel
  module SpecialisedFields
    class TagIndex < Base
      validates_presence_of :value
    end
  end
end