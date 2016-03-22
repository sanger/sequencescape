#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
FactoryGirl.define do
  sequence :asset_rack_name do |n|
    "TestRack#{n}"
  end

  factory :asset_rack do
    purpose  { |_| create :asset_rack_purpose }
    name     { FactoryGirl.generate :asset_rack_name }
    size 12
    ancestors { [create(:plate,:plate_purpose => PlatePurpose.find_by_name('Cherrypicked') )] }
  end

  factory :full_asset_rack, :parent => :asset_rack do
    after(:create) do |rack|
      rack.strip_tubes << create(:strip_tube)
    end
  end

  factory :fuller_asset_rack, :parent => :asset_rack do
    after(:create) do |rack|
      2.times do |column_index|
        rack.strip_tubes << create(:strip_tube,:map=>Map.find(:first,:conditions=>{:asset_size=>96,:asset_shape_id=>AssetShape.default,:row_order=>column_index}))
      end
    end
  end

  factory :asset_rack_purpose, :class => AssetRack::Purpose do
    name               { FactoryGirl.generate :purpose_name }
    size               "12"
    asset_shape        AssetShape.find_by_name('StripTubeRack')
    barcode_for_tecan  'ean13_barcode'
    target_type         'AssetRack'
  end

  factory :strip_tube_purpose, :class => PlatePurpose do
    name               { FactoryGirl.generate :purpose_name }
    size               "8"
    asset_shape        { AssetShape.find_by_name!('StripTubeColumn') }
    barcode_for_tecan  'ean13_barcode'
  end

  factory :strip_tube do
    name               "Strip_tube"
    size               "8"
    plate_purpose      { create :strip_tube_purpose }
    after(:create) do |st|
      st.wells.import(st.maps.map { |map| create(:well, :map => map) })
    end
  end

  factory(:asset_rack_creation) do
    user   { |target| target.association(:user) }
    parent { |target| target.association(:full_plate) }

    after(:build) do |asser_rack_creation|
      asser_rack_creation.parent.plate_purpose = PlatePurpose.find_by_name('Parent plate purpose') || create(:parent_plate_purpose)
      asser_rack_creation.child_purpose        = Purpose.find_by_name('Asset rack purpose')  || create(:child_plate_purpose)
    end
  end
end
