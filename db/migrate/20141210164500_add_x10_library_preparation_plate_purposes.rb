class AddX10LibraryPreparationPlatePurposes < ActiveRecord::Migration
  def self.up
    ActiveRecord::Base.transaction do
      IlluminaHtp::InitialDownstreamPlatePurpose.create!(
        :name => "Lib Norm",
        :can_be_considered_a_stock_plate => false,
        :default_state => "pending",
        :barcode_printer_type => BarcodePrinterType.find_by_name("96 Well Plate"),
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :cherrypick_direction => "column",
        :default_location => Location.find_by_name("Illumina high throughput freezer"),
        :size => 96,
        :barcode_for_tecan => "ean13_barcode"
      )

      IlluminaHtp::NormalizedPlatePurpose.create!(
        :name => "Lib Norm 2",
        :can_be_considered_a_stock_plate => false,
        :default_state => "pending",
        :barcode_printer_type => BarcodePrinterType.find_by_name("96 Well Plate"),
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :cherrypick_direction => "column",
        :default_location => Location.find_by_name("Illumina high throughput freezer"),
        :size => 96,
        :barcode_for_tecan => "ean13_barcode"
      )

      IlluminaHtp::PooledPlatePurpose.create!(
        :name => "Lib Norm 2 Pool",
        :can_be_considered_a_stock_plate => false,
        :default_state => "pending",
        :barcode_printer_type => BarcodePrinterType.find_by_name("96 Well Plate"),
        :cherrypickable_target => false,
        :cherrypickable_source => false,
        :cherrypick_direction => "column",
        :default_location => Location.find_by_name("Illumina high throughput freezer"),
        :size => 96,
        :barcode_for_tecan => "ean13_barcode"
      )
    end
  end

  def self.down
    ActiveRecord::Base.transaction do
      ["Lib Norm", "Lib Norm 2", "Lib Norm 2 Pool"].each do |name|
        PlatePurpose.find_by_name!(name).destroy
      end
    end
  end
end
