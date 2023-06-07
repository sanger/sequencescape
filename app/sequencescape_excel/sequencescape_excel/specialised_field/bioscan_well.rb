# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    # BioscanWell
    # Specialised field to link validations from bioscan control type
    class BioscanWell < Well
      include Base
      include ValueRequired
    end
  end
end
