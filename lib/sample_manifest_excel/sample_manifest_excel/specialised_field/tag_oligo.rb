module SampleManifestExcel
  module SpecialisedField
    class TagOligo
      include Base
      include Tags::AliquotUpdater

      set_tag_name :tag
    end
  end
end
