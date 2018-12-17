# frozen_string_literal: true

# AddLotNumberToQcAssay
class AddLotNumberToQcAssay < ActiveRecord::Migration[5.1]
  def change
    add_column :qc_assays, :lot_number, :string
  end
end
