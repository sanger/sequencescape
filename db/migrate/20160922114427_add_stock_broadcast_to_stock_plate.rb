# Rails migration
# Creator to generate stock messages
class AddStockBroadcastToStockPlate < ActiveRecord::Migration
  def change
    MessengerCreator.create!(purpose: Purpose.find_by(name: 'Stock Plate'), root: 'stock_resource', template: 'WellStockResourceIO', target_finder_class: 'WellFinder')
  end
end
