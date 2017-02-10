# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

require 'test_helper'

class CherrypickTaskTest < ActiveSupport::TestCase
  # Pads the cherrypicked view of a plate with empty wells
  def pad_expected_plate_with_empty_wells(template, plate)
    plate.concat([CherrypickTask::EMPTY_WELL] * (template.size - plate.size))
  end

  def maps_for(num, from = 0, order = 'column')
    Map.where(asset_shape_id: @asset_shape.id, asset_size: 12).order("#{order}_order ASC").all[from...num]
  end

  context CherrypickTask do
    setup do
      @asset_shape = AssetShape.create!(name: 'mini', horizontal_ratio: 4, vertical_ratio: 3, description_strategy: 'Map::Coordinate')

      ('A'..'C').map { |r| (1..4).map { |c| "#{r}#{c}" } }.flatten.each_with_index do |m, i|
        Map.create!(description: m, asset_size: 12, asset_shape_id: @asset_shape.id, location_id: i + 1, row_order: i, column_order: ((i / 4) + 3 * (i % 4)))
      end

      @mini_plate_purpose = PlatePurpose.stock_plate_purpose.clone.tap do |pp|
        pp.size = 12
        pp.name = 'Clonepp'
        pp.asset_shape = @asset_shape
        pp.save!
      end

      @pipeline = Pipeline.find_by(name: 'Cherrypick') or raise StandardError, 'Cannot find cherrypick pipeline'
      @task = CherrypickTask.new(workflow: @pipeline.workflow)

      @barcode = 10000

      @robot = mock('robot')
      @robot.stubs(:max_beds).returns(2)

      @batch    = mock('batch')

      @template = PlateTemplate.new(size: 12)
    end

    context '#pick_onto_partial_plate' do
      setup do
        plate = @mini_plate_purpose.create!(:without_wells, barcode: (@barcode += 1)) do |plate|
          plate.wells.build(maps_for(12).map { |m| { map: m } })
        end
        # TODO: This is very slow, and could do with improvements
        @requests = plate.wells.sort_by { |w| w.map.column_order }.map { |w| create(:well_request, asset: w) }
      end

      should 'error when the robot has no beds' do
        robot = mock('robot')
        robot.stubs(:max_beds).returns(0)

        partial = @mini_plate_purpose.create!(:without_wells, barcode: (@barcode += 1)) do |partial|
          partial.wells.build(maps_for(6).map { |m| { map: m } })
        end

        assert_raises(StandardError) do
          @task.pick_onto_partial_plate(nil, nil, robot, nil, partial)
        end
      end

      context 'that is column picked and has left 2 columns filled' do
        setup do
          plate_purpose = @mini_plate_purpose
          plate_purpose.update_attributes!(cherrypick_direction: 'column')
          @partial = plate_purpose.create!(:without_wells, barcode: (@barcode += 1)) do |partial|
            partial.wells.build(maps_for(6).map { |m| { map: m } })
          end
          @expected_partial = [CherrypickTask::TEMPLATE_EMPTY_WELL] * @partial.wells.size
        end

        should 'represent partial plate correctly when there are no picks made' do
          expected = [@expected_partial]
          pad_expected_plate_with_empty_wells(@template, expected.first)

          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)
          assert_equal(expected, plates, 'Incorrect partial plate representation')
        end

        should 'generate a second plate when the partial is full' do
          plates, source_plates = @task.pick_onto_partial_plate(@requests, @template, @robot, @batch, @partial)
          assert_equal(2, plates.size, 'Incorrect number of plates')
        end

        should 'fill plate with empty wells' do
          expected, requests = [@expected_partial], @requests.slice(0, 5)
          expected.first.concat(requests.map { |request| [request.id, request.asset.plate.barcode, request.asset.map.description] })
          pad_expected_plate_with_empty_wells(@template, expected.first)

          plates, source_plates = @task.pick_onto_partial_plate(requests, @template, @robot, @batch, @partial)
          assert_equal(expected, plates, 'Incorrect plate pick')
        end
      end

      context 'that is row picked and has top row filled' do
        setup do
          plate_purpose = @mini_plate_purpose
          plate_purpose.update_attributes!(cherrypick_direction: 'row')
          @partial = plate_purpose.create!(:without_wells, barcode: (@barcode += 1)) do |partial|
            partial.wells.build(maps_for(4, 0, 'row').map { |m| { map: m } })
          end
        end

        should 'represent partial plate correctly when there are no picks made' do
          expected = (1..4).inject([]) do |plate, _|
            plate.tap do
              plate.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 1)
              plate.concat([CherrypickTask::EMPTY_WELL] * 2)
            end
          end

          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)
          assert_equal([expected], plates, 'Incorrect partial plate representation')
        end

        should 'pick wells in rows' do
          expected = (1..4).inject([]) do |plate, row|
            plate.tap do
              request = @requests[row - 1]
              plate.concat([CherrypickTask::TEMPLATE_EMPTY_WELL])
              plate.push([request.id, request.asset.plate.barcode, request.asset.map.description])
              plate.concat([CherrypickTask::EMPTY_WELL])
            end
          end

          plates, source_plates = @task.pick_onto_partial_plate(@requests.slice(0, 4), @template, @robot, @batch, @partial)
          assert_equal([expected], plates, 'Incorrect partial plate representation')
        end
      end

      context 'with left & right columns filled' do
        setup do
          @partial = @mini_plate_purpose.create!(:without_wells, barcode: (@barcode += 1)) do |partial|
            ms = maps_for(3, 0, 'column').map { |m| { map: m } }
            ms.concat(maps_for(12, 9, 'column').map { |m| { map: m } })
            partial.wells.build(ms)
          end
        end

        should 'represent partial plate correctly when there are no picks made' do
          expected = []
          expected.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 3) # Column 1
          expected.concat([CherrypickTask::EMPTY_WELL] * 6) # Columns 2-11
          expected.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 3) # Column 12

          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)
          assert_equal([expected], plates, 'Incorrect partial plate representation')
        end

        should 'not pick on top of any wells that are already present' do
          plate    = @mini_plate_purpose.create!(barcode: (@barcode += 1))
          requests = plate.wells.in_column_major_order.map do |w|
            create(:well_request, asset: w)
          end

          expected_partial = []
          expected_partial.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 3) # Column 1
          expected_partial.concat(requests.slice(0, 6).map { |request| [request.id, request.asset.plate.barcode, request.asset.map.description] })
          expected_partial.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 3) # Column 12

          expected_second = requests.slice(6, 6).map { |request| [request.id, request.asset.plate.barcode, request.asset.map.description] }
          pad_expected_plate_with_empty_wells(@template, expected_second)

          plates, source_plates = @task.pick_onto_partial_plate(requests, @template, @robot, @batch, @partial)
          assert_equal([expected_partial, expected_second], plates, 'Incorrect partial plate representation')
        end
      end

      context 'where the template defines a control well' do
        setup do
          @partial = @mini_plate_purpose.create!(:without_wells, barcode: (@barcode += 1)) do |partial|
            partial.wells.build(maps_for(3).map { |m| { map: m } })
          end
          @expected_partial = [CherrypickTask::TEMPLATE_EMPTY_WELL] * @partial.wells.size
          pad_expected_plate_with_empty_wells(@template, @expected_partial)

          @template.set_control_well(1)

          @control_plate = ControlPlate.create!(barcode: (@barcode += 1), size: 12, plate_purpose: @mini_plate_purpose).tap do |plate|
            Map.where_plate_size(12).where_description(['A1', 'C1', 'A2']).all.each do |location|
              well = plate.wells.create!(map: location)
              well.aliquots.create!(sample: create(:sample))
            end
          end

          ControlPlate.any_instance.stubs(:illumina_wells).returns(@control_plate.wells.located_at(['A1', 'C1', 'A2']))
          @control_plate.stubs(:illumina_wells).returns(@control_plate.wells.located_at(['A1', 'C1', 'A2']))

          @batch = @pipeline.batches.create!
        end

        should 'add a control well to the plate in the bottom corner' do
          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)

          picked = plates.first
          control_well_details = picked.pop
          assert_equal(@expected_partial.slice(0, @expected_partial.size - 1), picked, 'Incorrect pick of plate up to control well')

          # To check the control well we have to account for the well being picked being random
          assert_equal(@batch.requests.first.id, control_well_details[0], 'Incorrect control request ID')
          assert_equal(@control_plate.barcode.to_s, control_well_details[1], 'Incorrect control plate barcode')
          assert(['A1', 'C1', 'A2'].include?(control_well_details[2]), 'Incorrect control well location')
        end

        should 'not add a control well to the plate if it already has one' do
          create(:well_request, asset: @control_plate.wells.first, target_asset: @partial.wells.first)

          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)
          assert_equal([@expected_partial], plates, 'Incorrect plate pick without control well')
        end

        should 'add a control request to the batch' do
          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)
          assert_equal(1, @batch.requests(true).size)
        end

        should 'add the control plate to the source list' do
          plates, source_plates = @task.pick_onto_partial_plate([], @template, @robot, @batch, @partial)
          assert(source_plates.include?(@control_plate.barcode.to_s), 'control plate not part of sources')
        end
      end
    end

    context '#pick_new_plate' do
      context 'with a plate purpose' do
        setup do
          plate     = @mini_plate_purpose.create!(barcode: (@barcode += 1))
          @requests = plate.wells.in_column_major_order.map { |w| create(:well_request, asset: w) }

          @target_purpose = @mini_plate_purpose
        end

        teardown do
          plates, source_plates = @task.pick_new_plate(@requests, @template, @robot, @batch, @target_purpose)
          assert_equal([@expected], plates, 'Incorrect plate pick')
        end

        should 'pick vertically when the plate purpose says so' do
          @target_purpose.update_attributes!(cherrypick_direction: 'column')
          @expected = @requests.map { |request| [request.id, request.asset.plate.barcode, request.asset.map.description] }
        end

        should 'pick horizontally when the plate purpose says so' do
          @target_purpose.update_attributes!(cherrypick_direction: 'row')
          @expected = (1..12).map do |index|
            request = @requests[@asset_shape.vertical_to_horizontal(index, @requests.size) - 1]
            [request.id, request.asset.plate.barcode, request.asset.map.description]
          end
        end
      end

      should 'error when the robot has no beds' do
        robot = mock('robot')
        robot.stubs(:max_beds).returns(0)

        assert_raises(StandardError) do
          @task.pick_new_plate(nil, nil, robot, nil, PlatePurpose.new(asset_shape: @asset_shape, size: 12))
        end
      end

      context 'with limited number of source beds' do
        setup do
          plates = (1..3).map { |_| @mini_plate_purpose.create!(barcode: (@barcode += 1)) }
          @requests = plates.map { |p| create(:well_request, asset: p.wells.first) }
          @expected = @requests.map do |request|
            [request.id, request.asset.plate.barcode, request.asset.map.description]
          end.in_groups_of(2).map do |group|
            group.compact!
            pad_expected_plate_with_empty_wells(@template, group)
          end
        end

        should 'not generate a second plate if beds are not full' do
          plates, source_plates = @task.pick_new_plate(@requests.slice(0, 2), @template, @robot, @batch, @target_purpose)
          assert_equal(@expected.slice(0, 1), plates, 'Incorrect plate pick')
          assert_equal(Set.new(@requests.slice(0, 2).map(&:asset).map(&:plate).map(&:barcode)), source_plates, 'Incorrect source plates used')
        end

        should 'generate new plate when all source beds are full' do
          plates, source_plates = @task.pick_new_plate(@requests, @template, @robot, @batch, @target_purpose)
          assert_equal(@expected, plates, 'Incorrect plate pick')
          assert_equal(Set.new(@requests.map(&:asset).map(&:plate).map(&:barcode)), source_plates, 'Incorrect source plates used')
        end
      end
    end
  end
end
