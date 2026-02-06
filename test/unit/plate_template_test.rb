# frozen_string_literal: true

require 'test_helper'

class PlateTemplateTest < ActiveSupport::TestCase
  context 'A plate template' do
    context 'with no empty wells' do
      setup do
        @template = create(:plate_template)
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
        @template = create(:plate_template)
        @old_wells = Well.count
        @template.update_params!(name: 'a', value: '2', wells: { 'A1' => '123' })
      end

      should 'be added' do
        assert_equal @old_wells + 1, Well.count
      end
    end

    context 'with 2 empty wells' do
      setup do
        @template = create(:plate_template)
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
