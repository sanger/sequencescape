# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class WellTest < ActiveSupport::TestCase
  context 'A well' do
    setup do
      @well = create :well
    end

    context 'with gender_markers results' do
      setup do
        @well.well_attribute.update_attributes!(gender_markers: ['M', 'F', 'F'])
      end
      should 'create an event if nothings changed and there are no previous events' do
        @well.update_gender_markers!(['M', 'F', 'F'], 'SNP')
        assert_equal 1, @well.events.count
      end

      should 'an event for each resource if nothings changed' do
        @well.update_gender_markers!(['M', 'F', 'F'], 'MSPEC')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
        @well.update_gender_markers!(['M', 'F', 'F'], 'SNP')
        assert_equal 2, @well.events.count
        assert 'SNP', @well.events.last.content
      end

      should 'only 1 event if nothings changed for the same resource' do
        @well.update_gender_markers!(['M', 'F', 'F'], 'SNP')
        assert_equal 1, @well.events.count
        assert 'SNP', @well.events.last.content
        @well.update_gender_markers!(['M', 'F', 'F'], 'SNP')
        assert_equal 1, @well.events.count
        assert 'SNP', @well.events.last.content
      end
    end

    context 'without gender_markers results' do
      should 'an event for each resource if its changed' do
        @well.update_gender_markers!(['M', 'F', 'F'], 'MSPEC')
        assert_equal 1, @well.events.count
        assert 'MSPEC', @well.events.last.content
        @well.update_gender_markers!(['M', 'F', 'F'], 'SNP')
        assert_equal 2, @well.events.count
        assert 'SNP', @well.events.last.content
      end
    end

    context 'with sequenom_count results' do
      setup do
       @well.well_attribute.update_attributes!(sequenom_count: 5)
      end

     should 'add an event if its changed' do
      @well.update_sequenom_count!(10, 'MSPEC')
      assert_equal 1, @well.events.count
      assert 'MSPEC', @well.events.last.content
      @well.update_sequenom_count!(10, 'SNP')
      assert_equal 1, @well.events.count
      assert 'MSPEC', @well.events.last.content
     end
    end

  context 'without sequenom_count results' do
    should 'add an event if its changed' do
      @well.update_sequenom_count!(10, 'MSPEC')
      assert_equal 1, @well.events.count
      assert 'MSPEC', @well.events.last.content
      @well.update_sequenom_count!(11, 'SNP')
      assert_equal 2, @well.events.count
      assert 'SNP', @well.events.last.content
    end
  end

  should 'return a correct hash of target wells' do
    purposes = create_list :plate_purpose, 4
    stock_plate = create :plate_with_untagged_wells, sample_count: 3

    norm_plates = purposes.map { |purpose| create :plate_with_untagged_wells, purpose: purpose, sample_count: 3 }

    well_plate_concentrations = [
      # Plate 1, Plate 2, Plate 3
      [50,       40,      60],  # Well 1
      [30,       nil,     nil], # Well 2
      [10,       nil,     nil]  # Well 3
    ]

    norm_plates.each_with_index do |plate, plate_index|
      plate.wells.each_with_index do |w, well_index|
        conc = well_plate_concentrations[well_index][plate_index]
        w.well_attribute.update_attributes(concentration: conc)
        stock_plate.wells[well_index].target_wells << w
      end
    end

    result = Well.hash_stock_with_targets(stock_plate.wells, purposes.map(&:name))

    assert_equal result.count, 3
    assert_equal result[stock_plate.wells[1].id].count, 1
    assert_equal result[stock_plate.wells[2].id].count, 1
    assert_equal result[stock_plate.wells[0].id].count, 3
  end

  should 'have pico pass' do
    @well.well_attribute.pico_pass = 'Yes'
    assert_equal 'Yes', @well.get_pico_pass
  end

  should 'have gel pass' do
    @well.well_attribute.gel_pass = 'Pass'
    assert_equal 'Pass', @well.get_gel_pass
    assert @well.get_gel_pass.is_a?(String)
  end

  should 'have picked volume' do
    @well.set_picked_volume(3.6)
    assert_equal 3.6, @well.get_picked_volume
  end

  should 'allow concentration to be set' do
    @well.set_concentration(1.0)
    concentration = @well.get_concentration
    assert_equal 1.0, concentration
    assert concentration.is_a?(Float)
  end

  should 'allow volume to be set' do
    @well.set_current_volume(2.5)
    vol = @well.get_volume
    assert_equal 2.5, vol
    assert vol.is_a?(Float)
  end

  should 'allow current volume to be set' do
    @well.set_current_volume(3.5)
    vol = @well.get_current_volume
    assert_equal 3.5, vol
    assert vol.is_a?(Float)
  end

  should 'record the initial volume as initial_volume' do
    @well.well_attribute.measured_volume = 3.5
    vol = @well.well_attribute.initial_volume
    assert_equal 3.5, vol
    @well.well_attribute.measured_volume = 2.5
    orig_vol = @well.well_attribute.initial_volume
    assert_equal 3.5, orig_vol
  end

  should 'allow buffer volume to be set' do
    @well.set_buffer_volume(4.5)
    vol = @well.get_buffer_volume
    assert_equal 4.5, vol
    assert vol.is_a?(Float)
  end

  context 'with a plate' do
    setup do
      @plate = create :plate
      @plate.add_and_save_well @well
    end
    should 'have a parent plate' do
      parent = @well.plate
      assert parent.is_a?(Plate)
      assert_equal parent.id, @plate.id
    end

    context 'for a tecan' do
      context 'with valid inputs' do
        setup do
          @well.map = Map.first
        end
        should 'return true' do
          assert !@well.map.nil?
          assert @well.valid_well_on_plate
        end
      end
      should 'have a parent plate' do
        parent = @well.plate
        assert parent.is_a?(Plate)
        assert_equal parent.id, @plate.id
      end

      context 'with nil parameters' do
        setup do
          @well_nil = Well.new
        end
        should 'return false' do
          assert_equal false, @well_nil.valid_well_on_plate
        end
      end
    end
  end

  [
    [1000, 10, 50, 50, 0, nil],
    [1000, 10, 10, 10, 0, nil],
    [1000, 10, 20, 10, 0, 10],
    [100, 100, 50, 1, 9, nil],
    [1000, 1000, 50, 1, 9, nil],
    [5000, 1000, 50, 5, 5, nil],
    [10, 100, 50, 1, 9, nil],
    [1000, 250, 50, 4, 6, nil],
    [10000, 250, 50, 40, 0, nil],
    [10000, 250, 30, 30, 0, nil]
  ].each do |target_ng, measured_concentration, measured_volume, stock_to_pick, buffer_added, current_volume|
    context 'cherrypick by nano grams' do
      setup do
        @source_well = create :well
        @target_well = create :well
        minimum_volume = 10
        maximum_volume = 50
        robot_minimum_picking_volume = 1.0
        @source_well.well_attribute.update_attributes!(concentration: measured_concentration, measured_volume: measured_volume, current_volume: current_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(minimum_volume, maximum_volume, target_ng, @source_well, robot_minimum_picking_volume)
      end
      should "output stock_to_pick #{stock_to_pick} for a target of #{target_ng} with vol #{measured_volume} and conc #{measured_concentration}" do
        assert_equal stock_to_pick, @target_well.well_attribute.picked_volume
      end
      should "output buffer #{buffer_added} for a target of #{target_ng} with vol #{measured_volume} and conc #{measured_concentration}" do
        assert_equal buffer_added, @target_well.well_attribute.buffer_volume
      end
    end
  end

  context 'when while cherrypicking by nanograms ' do
    context 'and we want to get less volume than the minimum' do
      setup do
        @source_well = create :well
        @target_well = create :well

        @measured_concentration = 100
        @measured_volume = 50
        @target_ng = 10
        @minimum_volume = 10
        @maximum_volume = 50
      end
      should 'get correct volume and buffer volume when there is not robot minimum picking volume' do
        stock_to_pick = 0.1
        buffer_added = 9.9
        robot_minimum_picking_volume = nil
        @source_well.well_attribute.update_attributes!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(@minimum_volume, @maximum_volume, @target_ng, @source_well, robot_minimum_picking_volume)
        assert_equal stock_to_pick, @target_well.get_picked_volume
        assert_equal buffer_added, @target_well.well_attribute.buffer_volume
      end
      should "get correct buffer volume when it's above robot minimum picking volume" do
        stock_to_pick = 1
        buffer_added = 9
        robot_minimum_picking_volume = 1.0
        @source_well.well_attribute.update_attributes!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(@minimum_volume, @maximum_volume, @target_ng, @source_well, robot_minimum_picking_volume)
        assert_equal stock_to_pick, @target_well.get_picked_volume
        assert_equal buffer_added, @target_well.well_attribute.buffer_volume
      end
      should 'get no buffer volume if the minimum picking volume exceeds the minimum volume' do
        stock_to_pick = 10.0
        buffer_added = 0.0
        robot_minimum_picking_volume = 10.0
        @source_well.well_attribute.update_attributes!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(@minimum_volume, @maximum_volume, @target_ng, @source_well, robot_minimum_picking_volume)
        assert_equal stock_to_pick, @target_well.get_picked_volume
        assert_equal buffer_added, @target_well.well_attribute.buffer_volume
      end
      should 'get robot minimum picking volume if the correct buffer volume is below this value' do
        stock_to_pick = 5.0
        buffer_added = 5.0
        robot_minimum_picking_volume = 5.0
        @source_well.well_attribute.update_attributes!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(@minimum_volume, @maximum_volume, @target_ng, @source_well, robot_minimum_picking_volume)
        assert_equal stock_to_pick, @target_well.get_picked_volume
        assert_equal buffer_added, @target_well.well_attribute.buffer_volume
      end
    end
  end

  context 'to be cherrypicked' do
    context 'with no source concentration' do
      should 'raise an error' do
        assert_raises Cherrypick::ConcentrationError do
          @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(1.1, 2.2, 0.0, 20)
          @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(1.2, 2.2, '', 20)
        end
      end
    end

    should 'return volume to pick' do
      assert_equal 1.25, @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0, 20)
      assert_equal 3.9,  @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(13.0, 30.0, 100.0, 20)
      assert_equal 9.1,  @well.get_buffer_volume
    end

    should 'sets the buffer volume' do
      vol_to_pick = @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0, 20)
      assert_equal 3.75, @well.get_buffer_volume
      vol_to_pick = @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(13.0, 30.0, 100.0, 20)
      assert_equal 9.1, @well.get_buffer_volume
    end

    should 'sets buffer and volume_to_pick correctly' do
      vol_to_pick = @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0, 20)
      assert_equal @well.get_picked_volume, vol_to_pick
      assert_equal 5.0, @well.get_buffer_volume + vol_to_pick
    end

    [
      [100.0, 50.0, 100.0,  200.0,  nil, 50.0,  50.0, 'Standard scenario, sufficient material, buffer and dna both added'],
      [100.0, 50.0, 100.0,  20.0,   nil, 20.0,  80.0, 'Insufficient source material for concentration or volume. Make up with buffer'],
      [100.0, 5.0,  100.0,  2.0,    nil, 2.0,   98.0, 'As above, just more extreme'],
      [100.0, 5.0,  100.0,  5.0,    5.0, 5.0,   95.0, 'High concentration, minimum robot volume increases source pick'],
      [100.0, 50.0, 52.0,   200.0,  5.0, 96.2,  5.0, 'Lowish concentration, non zero, but less than robot buffer required'],
      [100.0, 5.0,  100.0,  2.0,    5.0, 2.0,   98.0, 'Less DNA than robot minimum pick, fall back to DNA'],
      [100.0, 50.0, 1.0,    200.0,  5.0, 100.0, 0.0, 'Low concentration, maximum DNA, no buffer']
    ].each do |volume_required, concentration_required, source_concentration, source_volume, robot_minimum_pick_volume, volume_obtained, buffer_volume_obtained, scenario|
      context "when testing #{scenario}" do
        setup do
          @result_volume = ('%.1f' % @well.volume_to_cherrypick_by_nano_grams_per_micro_litre(volume_required,
            concentration_required, source_concentration, source_volume, robot_minimum_pick_volume)).to_f
          @result_buffer_volume = ('%.1f' % @well.get_buffer_volume).to_f
        end
        should 'gets correct volume quantity' do
          assert_equal volume_obtained, @result_volume
        end
        should 'gets correct buffer volume measures' do
          assert_equal buffer_volume_obtained, @result_buffer_volume
        end
      end
    end
  end
    context 'proceed test' do
      setup do
        @our_product_criteria = create :product_criteria
        @other_criteria = create :product_criteria

        @old_report = create :qc_report, product_criteria: @our_product_criteria, created_at: Time.now - 1.day, report_identifier: "A#{Time.now}"
        @current_report = create :qc_report, product_criteria: @our_product_criteria, created_at: Time.now - 1.hour, report_identifier: "B#{Time.now}"
        @unrelated_report = create :qc_report, product_criteria: @other_criteria, created_at: Time.now, report_identifier: "C#{Time.now}"

        @stock_well = create :well

        @well.stock_wells.attach!([@stock_well])
        @well.reload

        create :qc_metric, asset: @stock_well, qc_report: @old_report, qc_decision: 'passed', proceed: true
        create :qc_metric, asset: @stock_well, qc_report: @unrelated_report, qc_decision: 'passed', proceed: true

        @expected_metric = create :qc_metric, asset: @stock_well, qc_report: @current_report, qc_decision: 'failed', proceed: true
      end

      should 'report appropriate metrics' do
        assert_equal [@expected_metric], @well.latest_stock_metrics(@our_product_criteria.product)
      end
    end
  end
end
