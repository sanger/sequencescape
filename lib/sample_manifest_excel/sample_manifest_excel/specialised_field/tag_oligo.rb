module SampleManifestExcel
  module SpecialisedField
    class TagOligo
      include Base
      include Tags::AliquotUpdater
      include Tags::Validator::Formatting

      set_tag_name :tag
    end
  end
end
