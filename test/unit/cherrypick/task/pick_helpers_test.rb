# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

require 'test_helper'

class Cherrypick::Task::PickHelpersTest < ActiveSupport::TestCase
  context Cherrypick::Task::PickHelpers do
    setup do
      @barcode, @helper = 0, Object.new.tap do |helper|
        class << helper
          include Request::GroupingHelpers
          include Cherrypick::Task::PickHelpers
          public :cherrypick_wells_grouped_by_submission
        end
      end
    end

    context '#cherrypick_wells_grouped_by_submission' do
      setup do
        @requests = Map.where_plate_size(96).in_column_major_order.slice(0, 3).map do |position|
          create(
            :well_request,
            asset: create(:empty_well, map: position),
            target_asset: create(:empty_well),
            state: 'started',
            submission_id: 1
          ).tap do |request|
            request.asset.stubs(:plate).returns(OpenStruct.new(sanger_human_barcode: 1))
          end
        end

        @robot = OpenStruct.new(max_beds: 10)

        @callback = mock('Callback')
        @requests.each { |r| @callback.expects(:call).with(r.target_asset, r) }
      end

      context 'when the plate is to be picked in columns' do
        setup do
          plate_purpose = PlatePurpose.stock_plate_purpose
          plate_purpose.update_attributes!(cherrypick_direction: 'column')
          @plate = plate_purpose.create!(:do_not_create_wells, barcode: (@barcode += 1))

          @helper.cherrypick_wells_grouped_by_submission(@requests, @robot, @plate) { |*args| @callback.call(*args) }
          @requests.map(&:reload)
        end

        should 'passes the requests' do
          assert(@requests.all?(&:passed?), "Requests aren't passed")
        end

        should 'attach the wells to the plate' do
          assert_equal(@requests.size, @plate.wells.size, 'Mismatching number of wells to requests')
        end

        should 'lays out the wells in column order' do
          expected = Map.where_plate_size(@plate.size).where_plate_shape(@plate.asset_shape).in_column_major_order.slice(0, @requests.size)
          assert_equal(expected, @requests.map(&:target_asset).map(&:map), 'Wells in incorrect positions')
        end
      end

      context 'when the plate is to be picked in rows' do
        setup do
          plate_purpose = PlatePurpose.stock_plate_purpose
          plate_purpose.update_attributes!(cherrypick_direction: 'row')
          @plate = plate_purpose.create!(:do_not_create_wells, barcode: (@barcode += 1))

          @helper.cherrypick_wells_grouped_by_submission(@requests, @robot, @plate) { |*args| @callback.call(*args) }
          @requests.map(&:reload)
        end

        should 'lays out the wells in row order' do
          expected = Map.where_plate_size(@plate.size).where_plate_shape(@plate.asset_shape).in_row_major_order.slice(0, @requests.size)
          assert_equal(expected, @requests.map(&:target_asset).map(&:map), 'Wells in incorrect positions')
        end
      end
    end
  end
end
