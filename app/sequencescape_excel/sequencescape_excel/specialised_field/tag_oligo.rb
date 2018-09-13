# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # TagOligo
    class TagOligo
      include Base
      include SampleManifestExcel::Tags::AliquotUpdater
      include SampleManifestExcel::Tags::Validator::Formatting

      set_tag_name :tag
    end
  end
end
