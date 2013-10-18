class AddStockWellsToExistingWdPlates < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      AssetLink.find_each(
        :include => {
          :ancestor=>:wells,
          :descendant=>:wells
          },
        :joins => [
          %Q{INNER JOIN assets AS descendant ON
              asset_links.descendant_id = descendant.id}
        ],
        :conditions => "descendant.sti_type = 'WorkingDilutionPlate'"
      ) do |asset_link|
        next unless asset_link.ancestor.stock_plate?
        next if asset_link.descendant.wells.first.try(:stock_wells).present?
        say "Updating #{asset_link.descendant.id}"
        stock_wells = Hash[asset_link.ancestor.wells.map {|w| [w.map_description,w]}]
        asset_link.descendant.wells.each do |well|
          well.stock_wells.attach!([stock_wells[well.map_description]])
        end
      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
