# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

FactoryGirl.define do
  factory :lot_type do
    sequence(:name) { |n| "lot_type#{n}" }
    template_class 'PlateTemplate'
    target_purpose { Tube::Purpose.stock_library_tube }

    factory :tag2_lot_type do
      template_class 'Tag2LayoutTemplate'
    end
  end

  factory :pending_purpose, parent: :tube_purpose do
    name { FactoryGirl.generate :purpose_name }
    default_state 'pending'
  end

  factory :created_purpose, parent: :tube_purpose do
    name { FactoryGirl.generate :purpose_name }
    default_state 'created'
  end

  factory :qcable_creator do
    count 0
    user
    lot
  end

  factory :lot do
    sequence(:lot_number) { |n| "lot#{n}" }
    lot_type
    association(:template, factory: :plate_template_with_well)
    user
    received_at '2014-02-01'

    factory :tag2_lot do
      association(:lot_type, factory: :tag2_lot_type)
      association(:template, factory: :tag2_layout_template)
    end
  end

  factory :stamp do
    lot
    user
    robot
    tip_lot '555'
  end

  factory :qcable do
    # Note: We don't use the automatic association building here as
    # we rely on attributes_for, which doesn't seem to handle it well.
    # Incidentally we use attributes_for here as factory_girl instantiates
    # the object before setting attributes, which messes up the state machine
    # callbacks.
    lot { create :lot }
    qcable_creator { create :qcable_creator }

    factory :qcable_with_asset do
      state  'created'
      asset  { create :full_plate }
    end
  end

  factory :plate_template_with_well, class: PlateTemplate do
    name      'testtemplate2'
    value     96
    size      96
    wells { [create(:well_with_sample_and_without_plate, map: create(:map))] }
  end
end
