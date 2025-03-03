# frozen_string_literal: true
#
# This module provides helper methods for handling suppliers within UAT actions.
# If a supplier_name is provided, it will validate that the supplier exists. If
# no supplier_name is provided, it will use the default supplier.
#
# @example Including the SupplierHelper module
#  class SomeUatActionClass
#    include UatActions::SupplierHelper
#  end
module UatActions::Shared::SupplierHelper
  ERROR_SUPPLIER_DOES_NOT_EXIST = 'Supplier %s does not exist.'

  def self.included(base)
    base.class_eval { validate :validate_supplier_exists }
  end

  private

  # Returns the supplier if supplier_name is specified, otherwise returns the
  # default supplier. It assumes that if the supplier_name is specified, the
  # supplier is already validated.
  #
  # @return [Supplier] the Supplier object
  def supplier
    @supplier ||=
      if supplier_name.present?
        Supplier.find_by!(name: supplier_name) # already validated
      else
        UatActions::StaticRecords.supplier # default supplier
      end
  end

  # Validates that the supplier exists for the specified supplier_name. Empty
  # supplier_name is considered valid because the default supplier is used in that
  # case.
  #
  # @return [void]
  def validate_supplier_exists
    return if supplier_name.blank?
    return if Supplier.exists?(name: supplier_name)

    message = format(ERROR_SUPPLIER_DOES_NOT_EXIST, supplier_name)
    errors.add(:supplier_name, message)
  end
end
