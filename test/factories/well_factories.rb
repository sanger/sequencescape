#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2015 Genome Research Ltd.
FactoryGirl.define do
  factory :empty_well, :class => Well do |well|
    value               ""
    qc_state            ""
    resource            nil
    barcode             nil
    well_attribute      {|wa| wa.association(:well_attribute)}
  end

  factory :well, :parent => :empty_well do |a|
    # TODO: This should probably set an aliquot but test code (current) relies on it being empty
  end

  factory :nameless_well, :class => Well do |well|
    value               ""
    qc_state            ""
    resource            nil
    barcode             nil
    well_attribute      {|wa| wa.association(:well_attribute)}
  end

  factory :well_attribute do |w|
    concentration       23.2
    current_volume      15
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

