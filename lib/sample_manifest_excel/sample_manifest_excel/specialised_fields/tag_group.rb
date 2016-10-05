module SampleManifestExcel
  module SpecialisedFields
    class TagGroup < Base
      include TagGroupValidation
      validates_presence_of :value
    end
  end
end