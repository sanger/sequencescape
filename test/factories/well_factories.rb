# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015,2016 Genome Research Ltd.

FactoryGirl.define do
  factory :well do
    value               ''
    qc_state            ''
    resource            nil
    barcode             nil
    well_attribute

    # For compatibility.
    factory :empty_well
  end

  factory :well_attribute do
    concentration       23.2
    current_volume      15
  end

  factory :well_with_sample_and_without_plate, parent: :empty_well do
    after(:build) do |well|
      well.aliquots << build(:tagged_aliquot, receptacle: well)
    end
  end

  factory :untagged_well, parent: :empty_well do
    after(:build) do |well|
      well.aliquots << build(:untagged_aliquot, receptacle: well)
    end
  end

  factory :tagged_well, parent: :empty_well do
    after(:create) do |well|
      well.aliquots << build(:tagged_aliquot, receptacle: well)
    end
  end

  factory :well_with_sample_and_plate, parent: :well_with_sample_and_without_plate do
    map
    plate
  end

  factory :cross_pooled_well, parent: :empty_well do
    map
    plate
    after(:build) do |well|
      als = Array.new(2) {
        {
          sample:  create(:sample),
          study:   create(:study),
          project: create(:project),
          tag:     create(:tag)
        }
      }
      well.aliquots.build(als)
    end
  end

  factory :well_link, class: Well::Link do
    association(:source_well, factory: :well)
    association(:target_well, factory: :well)
    type 'stock'

    factory :stock_well_link
  end
end
