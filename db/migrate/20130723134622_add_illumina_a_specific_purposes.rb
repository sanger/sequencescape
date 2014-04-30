class AddIlluminaASpecificPurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      purpose = PlatePurpose.create!(
        :name                  => 'Post Shear XP',
        :cherrypickable_target => false,
        :cherrypick_direction  => 'column',
        :can_be_considered_a_stock_plate => false
      ).tap do |plate_purpose|
        plate_purpose.barcode_printer_type = BarcodePrinterType.find_by_type('BarcodePrinterType96Plate')||plate_purpose.barcode_printer_type
      end

    IlluminaHtp::PlatePurposes.create_branch([ 'Post Shear', 'Post Shear XP', 'AL Libs'])
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_by_name('Post Shear XP').destroy
    end
  end
end
