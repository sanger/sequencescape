module SampleManifestExcel
  module SpecialisedField
    class TagOligo
      include Base
      include Tagging

      set_tag_name :tag
    end
  end
end
