# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Same behaviour as base control type but using a different range
    # definition for the allowed control types used in Bioscan.
    # We also need to validate the supplier name starts with CONTROL_
    # when a control type is set.
    class BioscanControlType < ControlType
      attr_accessor :supplier_name

      validate :check_supplier_name

      def link(other_fields)
        self.supplier_name = other_fields[SequencescapeExcel::SpecialisedField::BioscanSupplierName]
      end

      private

      def check_supplier_name
        return if value.blank? || supplier_name&.value&.match?(/^CONTROL_\S+/)

        errors.add(:base, 'a control should have a supplier name beginning with CONTROL_.')
      end
    end
  end
end
