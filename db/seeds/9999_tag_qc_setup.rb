
tube = BarcodePrinterType.find_by_name('1D Tube')
plate = BarcodePrinterType.find_by_name('96 Well PLate')

purpose_order = [
      {:class=>PlatePurpose,    :name=>'Tag PCR', :barcode_printer_type => plate, :size => 96, :asset_shape => Map::AssetShape.find_by_name('Standard')},
      {:class=>PlatePurpose,    :name=>'Tag PCR-XP', :barcode_printer_type => plate, :size => 96, :asset_shape => Map::AssetShape.find_by_name('Standard')},
      {:class=>Tube::StockMx,   :name=>'Tag Stock-MX', :target_type=>'StockMultiplexedLibraryTube', :barcode_printer_type => tube},
      {:class=>Tube::StandardMx,:name=>'Tag MX', :target_type=>'MultiplexedLibraryTube', :barcode_printer_type => tube},
    ]

shared = {
  :can_be_considered_a_stock_plate => false,
  :default_state => 'pending',
  :cherrypickable_target => false,
  :cherrypick_direction => 'column',
  :barcode_for_tecan => 'ean13_barcode'
}

ActiveRecord::Base.transaction do
  initial = Purpose.find_by_name('Tag Plate')
  purpose_order.inject(initial) do |parent,child_settings|
    child_settings.delete(:class).create(child_settings.merge(shared)).tap do |child|
      parent.child_relationships.create!(:child => child, :transfer_request_type => RequestType.find_by_name('Transfer'))
    end
  end
end
