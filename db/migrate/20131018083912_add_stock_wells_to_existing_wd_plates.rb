class AddStockWellsToExistingWdPlates < ActiveRecord::Migration
  def self.up
    AssetLink.find_in_batches(
      :batch_size => 100,
      :include => {
        :ancestor=>:wells,
        :descendant=>:wells
        },
      :joins => [
        %Q{INNER JOIN assets AS descendant ON
            asset_links.descendant_id = descendant.id}
      ],
      :conditions => "descendant.sti_type = 'WorkingDilutionPlate'"
    ) do |batch|
      ActiveRecord::Base.transaction do
        batch.each do |asset_link|
          next unless asset_link.ancestor.stock_plate?
          next if asset_link.descendant.wells.detect {|w| w.try(:stock_wells).present? }
          say "Updating #{asset_link.descendant.id}"
          stock_wells = Hash[asset_link.ancestor.wells.compact.map {|w| [w.map_description,w]}]
          asset_link.descendant.wells.compact.each do |well|
            well.stock_wells.attach!([stock_wells[well.map_description]]) unless stock_wells[well.map_description].nil?
          end
          asset_link.clear_association_cache
        end

      end
    end
  end

  def self.down
    raise ActiveRecord::IrreversibleMigration
  end
end
