# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class LotTest < ActiveSupport::TestCase
  context 'A Lot' do
    should validate_presence_of :lot_number

    should have_many :qcables
    should belong_to :user
    should belong_to :lot_type
    should validate_presence_of :user
    should validate_presence_of :received_at
    should belong_to :template

    context 'when validating' do
      setup do
        create :lot
      end

      should validate_uniqueness_of :lot_number
    end

    context '#lot' do
      setup do
        PlateBarcode.stubs(:create).returns(OpenStruct.new(barcode: (FactoryGirl.generate :sanger_barcode)))
        @lot = create :lot
        @mock_asset = Asset.new
        @mock_asset.stubs(:save!).returns(true)
        @mock_purpose = mock('Purpose')

        @mock_purpose.stubs('create!').returns(@mock_asset)
        @lot.stubs(:target_purpose).returns(@mock_purpose)
        @user = create :user
      end

      should 'validate the template type' do
        @lot.template = create :tag_layout_template, name: 'lot_test'
        assert !@lot.valid?, 'Lot should be invalid'
      end

      teardown do
        @lot.lot_type.delete
        @lot.delete
      end
    end
  end
end
