# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # BioscanSupplierName
    # Same behaviour as base supplier name.
    # Just need a specialised field in this case so we can link the validations from the
    # bioscan control type to this field
    class BioscanSupplierName
      include Base
      include ValueRequired

      def update(_attributes = {})
        return unless valid?

        sample.sample_metadata.supplier_name = value if value.present?
      end
    end
  end
end
