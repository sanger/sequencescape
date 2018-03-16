# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexBarcodePrinterTypesOnPrinterTypeId < ActiveRecord::Migration[5.1]
  remove_index :barcode_printer_types, column: ['printer_type_id']
end
