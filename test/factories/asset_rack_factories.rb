Factory.sequence :asset_rack_name do |n|
  "TestRack#{n}"
end
Factory.sequence :purpose_name do |n|
  "Purpose#{n}"
end

Factory.define :asset_rack do |a|
  a.purpose  { |_| Factory :asset_rack_purpose }
  a.name     { Factory.next :asset_rack_name }
  a.size 12
  a.ancestors { [Factory(:plate,:plate_purpose => PlatePurpose.find_by_name('Cherrypicked') )] }
end

Factory.define :full_asset_rack, :parent => :asset_rack do |a|
  a.after_create do |rack|
    rack.strip_tubes << Factory(:strip_tube)
  end
end

Factory.define :fuller_asset_rack, :parent => :asset_rack do |a|
  a.after_create do |rack|
    2.times do |column_index|
      rack.strip_tubes << Factory(:strip_tube,:map=>Map.find(:first,:conditions=>{:asset_size=>96,:asset_shape_id=>Map::AssetShape.default,:row_order=>column_index}))
    end
  end
end

Factory.define :asset_rack_purpose, :class => AssetRack::Purpose do |a|
  a.name               { Factory.next :purpose_name }
  a.size               "12"
  a.asset_shape        Map::AssetShape.find_by_name('StripTubeRack')
  a.barcode_for_tecan  'ean13_barcode'
  a.target_type         'AssetRack'
end

Factory.define :strip_tube_purpose, :class => PlatePurpose do |a|
  a.name               { Factory.next :purpose_name }
  a.size               "8"
  a.asset_shape        { Map::AssetShape.find_by_name!('StripTubeColumn') }
  a.barcode_for_tecan  'ean13_barcode'
end

Factory.define :strip_tube do |a|
  a.name               "Strip_tube"
  a.size               "8"
  a.plate_purpose      { Factory :strip_tube_purpose }
  a.after_create do |st|
    st.wells.import(st.maps.map { |map| Factory(:well, :map => map) })
  end
end

Factory.define(:asset_rack_creation) do |asser_rack_creation|
  asser_rack_creation.user   { |target| target.association(:user) }
  asser_rack_creation.parent { |target| target.association(:full_plate) }

  asser_rack_creation.after_build do |asser_rack_creation|
    asser_rack_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || Factory(:parent_plate_purpose)
    asser_rack_creation.child_purpose        = Purpose.find_by_name('Asset rack purpose')  || Factory(:child_plate_purpose)
  end
end
