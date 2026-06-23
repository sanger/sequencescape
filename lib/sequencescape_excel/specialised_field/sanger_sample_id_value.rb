# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # SangerSampleIdValue
    module SangerSampleIdValue
      def value=(sample)
        @value = sample.sanger_sample_id
      end
    end
  end
end
