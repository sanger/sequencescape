class AddPacbioSequencingPlate < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      pbs = PlatePurpose.create!(
        :name=>'PacBio Sequencing',
        :target_type=>'Plate',
        :default_state=>'pending',
        :barcode_printer_type=>BarcodePrinterType.find_by_name('96 Well Plate'),
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :size => 96,
        :asset_shape => AssetShape.find_by_name('Standard'),
        :barcode_for_tecan => 'ean13_barcode'
      )
      AssignTubesToMultiplexedWellsTask.all.each {|task| task.update_attributes!(:purpose=>pbs)}
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      Purpose.find_by_name('PacBio Sequencing').destroy
    end
  end
end
