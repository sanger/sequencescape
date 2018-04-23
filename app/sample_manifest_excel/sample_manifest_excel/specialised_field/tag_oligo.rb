# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # TagOligo
    class TagOligo
      include Base
      include Tags::AliquotUpdater
      include Tags::Validator::Formatting

      set_tag_name :tag
    end
  end
end
