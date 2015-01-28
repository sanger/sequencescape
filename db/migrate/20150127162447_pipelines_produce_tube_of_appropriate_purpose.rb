class PipelinesProduceTubeOfAppropriatePurpose < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do

      say "Setting up Cap Lib Pool Norm"
      new_tube = IlluminaHtp::MxTubePurpose.create!(
        :name                  => 'Cap Lib Pool Norm',
        :target_type           => 'MultiplexedLibraryTube',
        :qc_display            => false,
        :can_be_considered_a_stock_plate => false,
        :default_state         => 'pending',
        :barcode_printer_type  => BarcodePrinterType.find_by_name('1D Tube'),
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :cherrypick_direction  => 'column',
        :barcode_for_tecan     => 'ean13_barcode'
      )
      RequestType.find_by_key('illumina_a_isc').update_attributes!(:target_purpose_id=>new_tube.id)
      Purpose.find_by_name('ISCH cap lib pool').child_relationships.first.update_attributes!(:child=>new_tube)

      say "Setting up Legacy MX tube"
      legacy_tube = IlluminaHtp::MxTubePurpose.create!(
        :name                  => 'Legacy MX tube',
        :target_type           => 'MultiplexedLibraryTube',
        :qc_display            => false,
        :can_be_considered_a_stock_plate => false,
        :default_state         => 'pending',
        :barcode_printer_type  => BarcodePrinterType.find_by_name('1D Tube'),
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :cherrypick_direction  => 'column',
        :barcode_for_tecan     => 'ean13_barcode'
      )
      [
        'pulldown_wgs','pulldown_sc','pulldown_isc',
        'illumina_a_pulldown_wgs','illumina_a_pulldown_sc',
        'illumina_a_pulldown_isc'
      ].each do |legacy_request_type|
        RequestType.find_by_key!(legacy_request_type).update_attributes!(:target_purpose_id=>legacy_tube.id)
      end
      Purpose.find_by_name('ISC cap lib pool').child_relationships.first.update_attributes!(:child=>legacy_tube)
      Purpose.find_by_name('SC cap lib pool').child_relationships.first.update_attributes!(:child=>legacy_tube)
      Purpose.find_by_name('WGS lib pool').child_relationships.first.update_attributes!(:child=>legacy_tube)
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      old_tube = Purpose.find_by_name('Standard MX')
      [
        'illumina_a_isc','pulldown_wgs','pulldown_sc','pulldown_isc',
        'illumina_a_pulldown_wgs','illumina_a_pulldown_sc',
        'illumina_a_pulldown_isc'
      ].each do |request_type|
        RequestType.find_by_key!(request_type).update_attributes!(:target_purpose_id=>old_tube.id)
      end
      Purpose.find_by_name('ISCH cap lib pool').child_relationships.first.update_attributes!(:child=>old_tube)
      Purpose.find_by_name('ISC cap lib pool').child_relationships.first.update_attributes!(:child=>old_tube)
      Purpose.find_by_name('SC cap lib pool').child_relationships.first.update_attributes!(:child=>old_tube)
      Purpose.find_by_name('WGS lib pool').child_relationships.first.update_attributes!(:child=>old_tube)
      IlluminaHtp::MxTubePurpose.find_by_name('Cap Lib Pool Norm').destroy
      IlluminaHtp::MxTubePurpose.find_by_name('Legacy MX tube').destroy
    end
  end
end
