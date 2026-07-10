# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # I5
    class I5
      include Base
      include SampleManifestExcel::Tags::AliquotUpdater
      include SampleManifestExcel::Tags::Validator::Formatting

      set_tag_name :tag2
    end
  end
end
