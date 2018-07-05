# frozen_string_literal: true

module SampleManifestExcel
  module SpecialisedField
    ##
    # Tag2Oligo
    class Tag2Oligo
      include Base
      include Tags::AliquotUpdater
      include Tags::Validator::Formatting

      set_tag_name :tag2
    end
  end
end
