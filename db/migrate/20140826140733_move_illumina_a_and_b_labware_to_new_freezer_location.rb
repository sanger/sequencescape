class MoveIlluminaAAndBLabwareToNewFreezerLocation < ActiveRecord::Migration
  
  def self.plate_purposes
    names = IlluminaB::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten.concat(IlluminaHtp::PlatePurposes::PLATE_PURPOSE_FLOWS.flatten)
    PlatePurpose.find_all_by_name(names)
  end

  def self.stock_plate_purposes
    PlatePurpose.find_all_by_name([IlluminaB::PlatePurposes::STOCK_PLATE_PURPOSE,IlluminaHtp::PlatePurposes::STOCK_PLATE_PURPOSE])
  end

  def self.freezer
    freezer_name = 'Illumina high throughput freezer'
    Location.find_by_name(freezer_name) or raise ActiveRecord::RecordNotFound, freezer_name
  end    

  def self.up
    ActiveRecord::Base.transaction do
      illumina_freezer = self.freezer
      ['Library creation freezer', 'Pulldown freezer'].map do |freezer_name| 
        Location.find_by_name(freezer_name)
      end.each do |location|
        changed = 0
        stock_changed = 0
        plates = Plate.include_plate_metadata.include_plate_purpose.with_plate_purpose(self.plate_purposes).with_no_outgoing_transfers.located_in(location)
        plates.each do |plate|
          plate.update_attributes(:location => illumina_freezer)
          changed += 1
        end
        stock_plates = Plate.include_plate_metadata.include_plate_purpose.with_plate_purpose(self.stock_plate_purposes).with_no_outgoing_transfers.located_in(location)
        stock_plates.each do |plate|
          plate.update_attributes(:location => illumina_freezer)
          stock_changed += 1
        end
        puts "Moved #{changed} plates and #{stock_changed} stock plates from #{location.name}"
      end
    end
  end

  def self.down
  end
end
