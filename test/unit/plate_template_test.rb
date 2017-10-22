# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class PlateTemplateTest < ActiveSupport::TestCase
  context 'A plate template' do
    [1, 0, '1'].each_with_index do |i, index|
      context "with a control well set to #{i} - #{index}" do
        setup do
          @template = create :plate_template
          @template.set_control_well(i)
        end

        should 'be saved' do
          assert_equal 1, @template.descriptors.size
        end
      end
    end
    context 'with a control well set to 0' do
      setup do
        @template = create :plate_template
        @template.set_control_well(0)
      end

      should 'return boolean' do
        assert_equal false, @template.control_well?
      end
    end

    context 'with a control well set to 1' do
      setup do
        @template = create :plate_template
        @template.set_control_well(1)
      end

      should 'return boolean' do
        assert @template.control_well?
      end
    end

    context 'with no empty wells' do
      setup do
        @template = create :plate_template
        @old_wells = Well.count
        @old_asset_link = AssetLink.count
        @template.update_params!(name: 'a', value: '2', wells: {})
      end
      should 'be not add anything' do
        assert_equal @old_wells, Well.count
        assert_equal @old_asset_link, AssetLink.count
      end
    end

    context 'with 1 empty well' do
      setup do
        @template = create :plate_template
        @old_wells = Well.count
        @template.update_params!(name: 'a', value: '2', wells: { 'A1' => '123' })
      end
      should 'be added' do
        assert_equal @old_wells + 1, Well.count
      end
    end

    context 'with 2 empty wells' do
      setup do
        @template = create :plate_template
        @old_wells = Well.count
        @old_asset_link = AssetLink.count
        @template.update_params!(name: 'a', value: '2', wells: { 'A1' => '123', 'B3' => '345' })
      end
      should 'be added' do
        assert_equal @old_wells + 2, Well.count
      end
    end
  end
end
