#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014,2015 Genome Research Ltd.

FactoryGirl.define do
  sequence :lot_number do |n|
    "lot#{n}"
  end
  sequence :lot_type_name do |n|
    "lot_type#{n}"
  end

  factory :lot_type do |lot_type|
    name           { FactoryGirl.generate :lot_type_name }
    template_class 'PlateTemplate'
    target_purpose { Tube::Purpose.stock_library_tube }
  end

  factory :pending_purpose, :parent => :tube_purpose do |pp|
    name { FactoryGirl.generate :purpose_name }
    default_state 'pending'
  end

  factory :created_purpose, :parent => :tube_purpose do |pp|
    name { FactoryGirl.generate :purpose_name }
    default_state 'created'
  end

  factory :tag2_lot_type, :parent=> :lot_type do |lot_type|
    name           { FactoryGirl.generate :lot_type_name }
    template_class 'Tag2LayoutTemplate'
    target_purpose { Tube::Purpose.stock_library_tube }
  end

  factory :qcable_creator do |qcable_creator|
    count    0
    user    { create :user }
    lot     { create :lot }
  end

  factory :lot do |lot|
    lot_number  { FactoryGirl.generate :lot_number }
    lot_type    { create :lot_type }
    template    { create :plate_template_with_well }
    user        { create :user }
    received_at '2014-02-01'
  end

  factory :tag2_lot, :parent => :lot do |lot|
    lot_number  { FactoryGirl.generate :lot_number }
    lot_type    { |a| create(:tag2_lot_type) }
    template    { |a| create(:tag2_layout_template) }
    user        { |a| create(:user) }
    received_at '2014-02-01'
  end

  factory :stamp do |stamp|
    lot     { create :lot }
    user    { create :user }
    robot   { create :robot }
    tip_lot '555'
  end

  factory :qcable do |qcable|
    lot    { create :lot }
    qcable_creator { create :qcable_creator }
  end

  factory :plate_template_with_well, :class=>PlateTemplate do |p|
    name      "testtemplate2"
    value     96
    size      96
    wells    { [create(:well_with_sample_and_without_plate,:map=>create(:map))] }
  end

  factory :qcable_with_asset, :class=>Qcable do |qcable|
    state  'created'
    lot    { create :lot }
    qcable_creator { create :qcable_creator }
    asset  {create :full_plate }
  end
end
