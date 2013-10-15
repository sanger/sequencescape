class FluidigmPlatesUseOwnBarcode < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      PlatePurpose.find_all_by_name(['Fluidigm 96-96','Fluidigm 192-24']).each do |purpose|
        purpose.update_attributes!(:barcode_for_tecan=>'fluidigm_barcode')
      end
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      PlatePurpose.find_all_by_name(['Fluidigm 96-96','Fluidigm 192-24']).each do |purpose|
        purpose.update_attributes!(:barcode_for_tecan=>'ean13_barcode')
      end
    end
  end
end
