# frozen_string_literal: true

# Auto generated migration to remove unused indexes
class RemoveIndexImplementsOnBarcode < ActiveRecord::Migration[5.1]
  remove_index :implements, column: ['barcode']
end
