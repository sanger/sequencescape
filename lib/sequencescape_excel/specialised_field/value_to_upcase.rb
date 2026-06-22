# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # ValueToUpcase
    module ValueToUpcase
      def value=(value)
        @value = value.upcase if value.present?
      end
    end
  end
end
