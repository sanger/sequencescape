# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class LotTypeTest < ActiveSupport::TestCase
  context 'A Lot Type' do
    context 'validating' do
      setup do
        create :lot
      end

      should validate_uniqueness_of :name
    end
    should validate_presence_of :name
    should validate_presence_of :template_class

    should have_many :lots
    should belong_to :target_purpose

    context '#lot' do
      setup do
        @lot_type = create :lot_type
        @user = create :user
        @template = PlateTemplate.new
      end

      context 'create' do
        setup do
          @lot_count = Lot.count
          @lot = @lot_type.create!(template: @template, user: @user, lot_number: '123456789', received_at: '2014-02-01')
        end

        should 'change Lot.count by 1' do
          assert_equal 1, Lot.count - @lot_count, 'Expected Lot.count to change by 1'
        end

        should 'set the lot properties' do
          assert_equal @user, @lot.user
          assert_equal '123456789', @lot.lot_number
        end
      end
    end
  end
end
