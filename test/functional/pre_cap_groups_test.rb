# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

require 'test_helper'

class PreCapGroupsTest < ActiveSupport::TestCase
  def with_pools(*pools)
    pools.each_with_index do |well_locs, index|
      @plate.wells.located_at(well_locs).each do |well|
       FactoryGirl.create(:pulldown_isc_request, asset: well,
                                                 pre_capture_pool: @pools[index],
                                                 submission_id: index + 1)
      end
    end
  end

  context 'A plate' do
    setup do
      @plate = FactoryGirl.create :pooling_plate
      @pools = (0..3).map do |i|
        pool = FactoryGirl.create :pre_capture_pool
        pool.uuid_object.update_attributes!(external_id: "00000000-0000-0000-0000-00000000000#{i}")
        pool
      end
    end

    context 'with two distinct pools' do
      setup do
        with_pools(['A1', 'B1', 'C1'], ['D1', 'E1', 'F1'])
      end

      should 'report two pools' do
        assert_equal([
          ['00000000-0000-0000-0000-000000000000', ['A1', 'B1', 'C1']],
          ['00000000-0000-0000-0000-000000000001', ['D1', 'E1', 'F1']]
        ], @plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] })
      end
    end

    context 'with overlapping distinct pools' do
      setup do
        with_pools(['A1', 'B1', 'C1'], ['D1', 'E1', 'F1'], ['A1', 'D1'])
      end

      context 'when all are pending' do
        should 'still report all the pools' do
          assert_equal([
            ['00000000-0000-0000-0000-000000000000', ['A1', 'B1', 'C1']],
            ['00000000-0000-0000-0000-000000000001', ['D1', 'E1', 'F1']],
            ['00000000-0000-0000-0000-000000000002', ['A1', 'D1']]
          ], @plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] })
        end
      end

      context 'when transfers are created' do
        setup do
          @target_plate = FactoryGirl.create :initial_downstream_plate
          @transfer = Transfer::BetweenPlates.create!(
            source: @plate.reload,
            destination: @target_plate.reload,
            user: FactoryGirl.create(:user),
            transfers: { 'A1' => ['A1', 'B1'], 'B1' => ['A1'], 'C1' => ['A1'], 'D1' => ['B1', 'C1'], 'E1' => ['C1'], 'F1' => ['C1'] }
          )
        end

        should 'assign requests to the right submissions' do
          transfer_sub = {
            'A1' => { 'A1' => 1, 'B1' => 3 }, 'B1' => { 'A1' => 1 }, 'C1' => { 'A1' => 1 },
            'D1' => { 'C1' => 2, 'B1' => 3 }, 'E1' => { 'C1' => 2 }, 'F1' => { 'C1' => 2 },
          }
          assert_equal 8, @target_plate.transfer_requests.count
          @target_plate.transfer_requests.each do |request|
            assert_equal transfer_sub[request.asset.map_description][request.target_asset.map_description], request.submission_id
          end
        end
      end

      context 'when some are started' do
        setup do
          @pools[0, 2].each { |pl| pl.requests.each { |r| r.update_attributes!(state: 'started') } }
        end

        should 'report the unstarted pool' do
          assert_equal 6, @plate.wells.count
          assert_equal([
            ['00000000-0000-0000-0000-000000000002', ['A1', 'D1']]
          ], @plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] })
        end
      end
    end
  end
end
