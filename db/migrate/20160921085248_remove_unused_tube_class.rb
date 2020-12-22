# Rails migration
# Clear up an unused tube class
class RemoveUnusedTubeClass < ActiveRecord::Migration
  class Purpose < ApplicationRecord # rubocop:todo Style/Documentation
    self.table_name = 'plate_purposes'
    self.inheritance_column = nil
    has_many :assets, foreign_key: 'plate_purpose_id'
  end

  def up
    candidates_for_removal = Purpose.where(target_type: 'StockSampleTube')
    candidates_for_removal.each do |purpose|
      raise StandardError, "#{purpose.id}: #{purpose.name} is used!" if purpose.assets.present?
    end
    ActiveRecord::Base.transaction { candidates_for_removal.each(&:destroy) }
  end

  def down
    ActiveRecord::Base.transaction do
      Tube::Purpose.create!(
        name: 'Stock sample',
        target_type: 'StockSampleTube',
        qc_display: false,
        can_be_considered_a_stock_plate: false,
        default_state: 'pending',
        barcode_printer_type_id: BarcodePrinterType.find_by(name: '1D Tube'),
        barcode_for_tecan: 'ean13_barcode'
      )
    end
  end
end
