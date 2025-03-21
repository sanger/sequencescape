# frozen_string_literal: true

# This UAT action creates a supplier with the provided name if it does not
# already exist. It can be used when custom suppliers are needed for testing.
class UatActions::GenerateSupplier < UatActions
  self.title = 'Generate supplier'
  self.description = 'Generate a simple supplier with the provided name.'
  self.category = :setup_and_test

  # Only the supplier name is required for this UAT action.
  form_field :supplier_name, :text_field, label: 'Supplier Name', help: 'The name of the supplier.'

  # The default supplier name is used if no supplier name is provided.
  def self.default
    new(supplier_name: UatActions::StaticRecords.supplier.name)
  end

  # Creates the supplier and prints the supplier ID to the report.
  # @return [Boolean] true if the UAT action was successful
  def perform
    supplier = create_supplier
    print_report(supplier)
    true
  end

  # Creates the supplier with the provided name if it does not already exist.
  # @return [Supplier] the Supplier object
  def create_supplier
    Supplier.find_or_create_by!(name: supplier_name)
  end

  private

  # Adds the supplier ID to the report.
  # @param supplier [Supplier] the Supplier object
  # @return [void]
  def print_report(supplier)
    report['supplier_id'] = supplier.id
  end
end
