# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # I7
    class I7
      include Base
      include SampleManifestExcel::Tags::AliquotUpdater
      include SampleManifestExcel::Tags::Validator::Formatting

      set_tag_name :tag
    end
  end
end
