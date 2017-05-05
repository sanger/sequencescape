module SampleManifestExcel
  module SpecialisedField
    class Tag2Oligo
      include Base
      include Tags::AliquotUpdater
      include Tags::Validator::Formatting

      set_tag_name :tag2
    end
  end
end
