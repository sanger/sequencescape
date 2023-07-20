# frozen_string_literal: true

module SequencescapeExcel
  module SpecialisedField
    ##
    # Same behaviour as base control type but using a different range
    # definition for the allowed control types used in Bioscan.
    # We also need to validate the supplier name starts with CONTROL_
    # when a control type is set.
    # We validate well restriction if control type is set:
    # 'pcr positive' or 'pcr negative' cannot be in H12
    # 'lysate negative' control (if present) can only be in H12
    class BioscanControlType < ControlType
      include Base

      attr_accessor :supplier_name, :well

      validate :check_supplier_name
      validate :check_well_position

      def link(other_fields)
        self.supplier_name = other_fields[SequencescapeExcel::SpecialisedField::BioscanSupplierName]
        self.well = other_fields[SequencescapeExcel::SpecialisedField::Well]
      end

      private

      def check_supplier_name
        return if value.blank? || supplier_name&.value&.match?(/^CONTROL_\S+/)

        errors.add(:base, 'a control should have a supplier name beginning with CONTROL_.')
      end

      def check_well_position
        if (['pcr positive', 'pcr negative'].include? value) && (well&.value == 'H12')
          errors.add(:base, 'pcr positive or pcr negative controls cannot be in H12.')
        elsif value == 'lysate negative' && well&.value != 'H12'
          errors.add(:base, 'lysate negative control (if present) must be in H12.')
        end
      end
    end
  end
end
