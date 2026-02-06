# frozen_string_literal: true

require 'test_helper'

class PreCapGroupsTest < ActiveSupport::TestCase
  def with_pools(*pools)
    pools.each_with_index do |well_locs, index|
      @plate
        .wells
        .located_at(well_locs)
        .each do |well|
          create(:pulldown_isc_request, asset: well, pre_capture_pool: @pools[index], submission_id: index + 1)
        end
    end
  end

  context 'A plate' do
    setup do
      @plate = create(:pooling_plate)
      @pools = create_list(:pre_capture_pool, 3)
    end

    context 'with two distinct pools' do
      setup { with_pools(%w[A1 B1 C1], %w[D1 E1 F1]) }

      should 'report two pools' do
        assert_equal(
          [[@pools[0].uuid, %w[A1 B1 C1]], [@pools[1].uuid, %w[D1 E1 F1]]],
          @plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] }
        )
      end
    end

    context 'with overlapping distinct pools' do
      setup { with_pools(%w[A1 B1 C1], %w[D1 E1 F1], %w[A1 D1]) }

      context 'when all are pending' do
        should 'still report all the pools' do
          assert_equal(
            [[@pools[0].uuid, %w[A1 B1 C1]], [@pools[1].uuid, %w[D1 E1 F1]], [@pools[2].uuid, %w[A1 D1]]],
            @plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] }
          )
        end
      end

      context 'when transfers are created' do
        setup do
          @target_plate = create(:plate_with_empty_wells)
          @transfer =
            Transfer::BetweenPlates.create!(
              source: @plate.reload,
              destination: @target_plate.reload,
              user: FactoryBot.create(:user),
              transfers: {
                'A1' => %w[A1 B1],
                'B1' => ['A1'],
                'C1' => ['A1'],
                'D1' => %w[B1 C1],
                'E1' => ['C1'],
                'F1' => ['C1']
              }
            )
        end

        should 'assign requests to the right submissions' do
          transfer_sub = {
            'A1' => {
              'A1' => 1,
              'B1' => 3
            },
            'B1' => {
              'A1' => 1
            },
            'C1' => {
              'A1' => 1
            },
            'D1' => {
              'C1' => 2,
              'B1' => 3
            },
            'E1' => {
              'C1' => 2
            },
            'F1' => {
              'C1' => 2
            }
          }

          assert_equal 8, @target_plate.transfer_requests.count
          @target_plate.transfer_requests.each do |request|
            assert_equal transfer_sub[request.asset.map_description][request.target_asset.map_description],
                         request.submission_id
          end
        end
      end

      context 'when some are started' do
        setup { @pools[0, 2].each { |pl| pl.requests.each { |r| r.update!(state: 'started') } } }

        should 'still report all the pools' do
          assert_equal(
            [[@pools[0].uuid, %w[A1 B1 C1]], [@pools[1].uuid, %w[D1 E1 F1]], [@pools[2].uuid, %w[A1 D1]]],
            @plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] }
          )
        end
      end
    end
  end

  context 'A non-stock plate' do
    # Pre-capture pools need to be available on downstream plate
    # Usually this just involve looking back at the stock wells.
    # However re-pooling request may be made from plates further
    # down the pipeline, and these won't be stock wells by default.
    # We need to ensure we still see all pools, regardless of which
    # plate they were made on.
    setup do
      @plate = create(:input_plate_for_pooling)
      @test_plate = create(:non_stock_pooling_plate)
      @pools = create_list(:pre_capture_pool, 3)
      with_pools(%w[A1 B1 C1], %w[D1 E1 F1])
      transfers = @test_plate.wells.each_with_object({}) { |w, hash| hash[w.map_description] = w.map_description }
      create(:transfer_between_plates, transfers: transfers, source: @plate, destination: @test_plate)
    end

    should 'report the pools from the stock plate' do
      assert_equal(
        [[@pools[0].uuid, %w[A1 B1 C1]], [@pools[1].uuid, %w[D1 E1 F1]]],
        @test_plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] }
      )
    end

    context 'with repooling requests downstream' do
      setup do
        @test_plate
          .wells
          .located_at(%w[A1 D1])
          .each { |well| create(:re_isc_request, asset: well, pre_capture_pool: @pools[2], submission_id: 3) }
      end

      should 'include all pools' do
        assert_equal(
          [[@pools[0].uuid, %w[A1 B1 C1]], [@pools[1].uuid, %w[D1 E1 F1]], [@pools[2].uuid, %w[A1 D1]]],
          @test_plate.pre_cap_groups.map { |pool, options| [pool, options[:wells].sort] }
        )
      end
    end
  end
end
