#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2015,2016 Genome Research Ltd.

FactoryGirl.define do

  factory :well do |a|
    value               ""
    qc_state            ""
    well_attribute

    # Empty well inherits from well and behaves identically
    factory :empty_well

  end

  factory :well_attribute do |w|
    concentration       23.2
    current_volume      15
    gel_pass            "Pass"
    pico_pass           "Pass"
    sequenom_count      2
  end

  factory :well_with_sample_and_without_plate, :parent => :empty_well do |well|
    after(:build) do |well|
      well.aliquots << create(:aliquot, :receptacle => well)
    end
  end

  factory :tagged_well, :parent => :empty_well do |well|
    after(:create) do |well|
      well.aliquots.create!(:sample => create(:sample), :tag => create(:tag))
    end
  end

  factory :well_with_sample_and_plate, :parent => :well_with_sample_and_without_plate do |well|
    map { |map| map.association(:map) }
    plate { |plate| plate.association(:plate) }
  end

  factory :cross_pooled_well, :parent => :empty_well do |well|
    map { |map| map.association(:map) }
    plate { |plate| plate.association(:plate) }
    after(:build) do |well|
      als = 2.times.map {
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
end

