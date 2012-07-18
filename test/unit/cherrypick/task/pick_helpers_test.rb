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
          Factory(:request, :asset => Factory(:empty_well, :map => position), :target_asset => Factory(:empty_well), :state => 'started', :submission_id => 1)
        end

        @callback = mock('Callback')
        @requests.each { |r| @callback.expects(:call).with(r.target_asset, r) }
      end

      context 'when the plate is to be picked in columns' do
        setup do
          plate_purpose = PlatePurpose.stock_plate_purpose
          plate_purpose.update_attributes!(:cherrypick_direction => 'column')
          @plate = plate_purpose.create!(:do_not_create_wells, :barcode => (@barcode += 1))

          @helper.cherrypick_wells_grouped_by_submission(@requests, @plate) { |*args| @callback.call(*args) }
          @requests.map(&:reload)
        end

        should 'passes the requests' do
          assert(@requests.all?(&:passed?), "Requests aren't passed")
        end

        should 'attach the wells to the plate' do
          assert_equal(@requests.size, @plate.wells.size, "Mismatching number of wells to requests")
        end

        should 'lays out the wells in column order' do
          expected = Map.where_plate_size(@plate.size).in_column_major_order.slice(0, @requests.size)
          assert_equal(expected, @requests.map(&:target_asset).map(&:map), "Wells in incorrect positions")
        end
      end

      context 'when the plate is to be picked in rows' do
        setup do
          plate_purpose = PlatePurpose.stock_plate_purpose
          plate_purpose.update_attributes!(:cherrypick_direction => 'row')
          @plate = plate_purpose.create!(:do_not_create_wells, :barcode => (@barcode += 1))

          @helper.cherrypick_wells_grouped_by_submission(@requests, @plate) { |*args| @callback.call(*args) }
          @requests.map(&:reload)
        end

        should 'lays out the wells in row order' do
          expected = Map.where_plate_size(@plate.size).in_row_major_order.slice(0, @requests.size)
          assert_equal(expected, @requests.map(&:target_asset).map(&:map), "Wells in incorrect positions")
        end
      end
    end
  end
end
