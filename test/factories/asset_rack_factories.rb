# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
FactoryGirl.define do
  factory :strip_tube_purpose, class: PlatePurpose do
    name               { FactoryGirl.generate :purpose_name }
    size               '8'
    asset_shape        { AssetShape.find_by!(name: 'StripTubeColumn') }
    barcode_for_tecan  'ean13_barcode'
  end

  factory :strip_tube do
    name               'Strip_tube'
    size               '8'
    plate_purpose      { create :strip_tube_purpose }
    after(:create) do |st|
      st.wells = st.maps.map { |map| create(:well, map: map) }
    end
  end
end
