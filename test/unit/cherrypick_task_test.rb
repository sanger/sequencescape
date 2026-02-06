# frozen_string_literal: true

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
      PlateBarcode.stubs(:create_child_barcodes).returns([build(:child_plate_barcode)])

      PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode))

      @asset_shape =
        AssetShape.create!(
          name: 'mini',
          horizontal_ratio: 4,
          vertical_ratio: 3,
          description_strategy: 'Map::Coordinate'
        )

      ('A'..'C')
        .map { |r| (1..4).map { |c| "#{r}#{c}" } }
        .flatten
        .each_with_index do |m, i|
          Map.create!(
            description: m,
            asset_size: 12,
            asset_shape_id: @asset_shape.id,
            location_id: i + 1,
            row_order: i,
            column_order: ((i / 4) + (3 * (i % 4)))
          )
        end

      @mini_plate_purpose =
        PlatePurpose.stock_plate_purpose.clone.tap do |pp|
          pp.size = 12
          pp.name = 'Clonepp'
          pp.asset_shape = @asset_shape
          pp.save!
        end

      @task = build(:cherrypick_task)

      @robot = mock('robot')
      @robot.stubs(:max_beds).returns(2)

      @batch = mock('batch')

      @template = PlateTemplate.new(size: 12)

      LabWhereClient::LabwareSearch.stubs(:find_locations_by_barcodes).returns(nil)
    end

    context '#pick_onto_partial_plate' do
      setup do
        plate = @mini_plate_purpose.create! { |created_plate| created_plate.barcodes = [build(:plate_barcode)] }

        # TODO: This is very slow, and could do with improvements
        @requests = plate.wells.sort_by { |w| w.map.column_order }.map { |w| create(:well_request, asset: w) }
      end

      should 'error when the robot has no beds' do
        robot = mock('robot')
        robot.stubs(:max_beds).returns(0)

        partial =
          @mini_plate_purpose.create!(:without_wells) do |plate|
            plate.barcodes = [build(:plate_barcode)]
            plate.wells.build(maps_for(6).map { |m| { map: m } })
          end

        assert_raises(StandardError) { @task.pick_onto_partial_plate(nil, nil, robot, nil, partial) }
      end

      context 'that is column picked and has left 2 columns filled' do
        setup do
          plate_purpose = @mini_plate_purpose
          plate_purpose.update!(cherrypick_direction: 'column')
          @partial =
            plate_purpose.create!(:without_wells) do |partial|
              partial.barcodes = [build(:plate_barcode)]
              partial.wells.build(maps_for(6).map { |m| { map: m } })
            end
          @expected_partial = [CherrypickTask::TEMPLATE_EMPTY_WELL] * @partial.wells.size
        end

        should 'represent partial plate correctly when there are no picks made' do
          expected = [@expected_partial]
          pad_expected_plate_with_empty_wells(@template, expected.first)

          plates, _source_plates = @task.pick_onto_partial_plate([], @template, @robot, @partial)

          assert_equal(expected, plates, 'Incorrect partial plate representation')
        end

        should 'generate a second plate when the partial is full' do
          plates, _source_plates = @task.pick_onto_partial_plate(@requests, @template, @robot, @partial)

          assert_equal(2, plates.size, 'Incorrect number of plates')
        end

        should 'fill plate with empty wells' do
          expected = [@expected_partial]
          requests = @requests.slice(0, 5)
          expected.first.concat(
            requests.map { |request| [request.id, request.asset.plate.human_barcode, request.asset.map.description] }
          )
          pad_expected_plate_with_empty_wells(@template, expected.first)

          plates, _source_plates = @task.pick_onto_partial_plate(requests, @template, @robot, @partial)

          assert_equal(expected, plates, 'Incorrect plate pick')
        end
      end

      context 'that is row picked and has top row filled' do
        setup do
          plate_purpose = @mini_plate_purpose
          plate_purpose.update!(cherrypick_direction: 'row')
          @partial =
            plate_purpose.create!(:without_wells) do |partial|
              partial.barcodes = [build(:plate_barcode)]
              partial.wells.build(maps_for(4, 0, 'row').map { |m| { map: m } })
            end
        end

        should 'represent partial plate correctly when there are no picks made' do
          expected =
            (1..4).inject([]) do |plate, _|
              plate.tap do
                plate.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 1)
                plate.concat([CherrypickTask::EMPTY_WELL] * 2)
              end
            end

          plates, _source_plates = @task.pick_onto_partial_plate([], @template, @robot, @partial)

          assert_equal([expected], plates, 'Incorrect partial plate representation')
        end

        should 'pick wells in rows' do
          expected =
            (1..4).inject([]) do |plate, row|
              plate.tap do
                request = @requests[row - 1]
                plate.push(CherrypickTask::TEMPLATE_EMPTY_WELL)
                plate.push([request.id, request.asset.plate.human_barcode, request.asset.map.description])
                plate.push(CherrypickTask::EMPTY_WELL)
              end
            end

          plates, _source_plates = @task.pick_onto_partial_plate(@requests.slice(0, 4), @template, @robot, @partial)

          assert_equal([expected], plates, 'Incorrect partial plate representation')
        end
      end

      context 'with left & right columns filled' do
        setup do
          @partial =
            @mini_plate_purpose.create!(:without_wells) do |partial|
              partial.barcodes = [build(:plate_barcode)]
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

          plates, _source_plates = @task.pick_onto_partial_plate([], @template, @robot, @partial)

          assert_equal([expected], plates, 'Incorrect partial plate representation')
        end

        should 'not pick on top of any wells that are already present' do
          plate = @mini_plate_purpose.create! { |created_plate| created_plate.barcodes = [build(:plate_barcode)] }
          requests = plate.wells.in_column_major_order.map { |w| create(:well_request, asset: w) }

          expected_partial = []
          expected_partial.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 3) # Column 1
          expected_partial.concat(
            requests
              .slice(0, 6)
              .map { |request| [request.id, request.asset.plate.human_barcode, request.asset.map.description] }
          )
          expected_partial.concat([CherrypickTask::TEMPLATE_EMPTY_WELL] * 3) # Column 12

          expected_second =
            requests
              .slice(6, 6)
              .map { |request| [request.id, request.asset.plate.human_barcode, request.asset.map.description] }
          pad_expected_plate_with_empty_wells(@template, expected_second)

          plates, _source_plates = @task.pick_onto_partial_plate(requests, @template, @robot, @partial)

          assert_equal([expected_partial, expected_second], plates, 'Incorrect partial plate representation')
        end
      end
    end

    context '#pick_new_plate' do
      context 'with a plate purpose' do
        setup do
          plate = @mini_plate_purpose.create! { |created_plate| created_plate.barcodes = [build(:plate_barcode)] }
          @requests = plate.wells.in_column_major_order.map { |w| create(:well_request, asset: w) }

          @target_purpose = @mini_plate_purpose
        end

        teardown do
          plates, _source_plates = @task.pick_new_plate(@requests, @template, @robot, @target_purpose)

          assert_equal([@expected], plates, 'Incorrect plate pick')
        end

        should 'pick vertically when the plate purpose says so' do
          @target_purpose.update!(cherrypick_direction: 'column')
          @expected =
            @requests.map { |request| [request.id, request.asset.plate.human_barcode, request.asset.map.description] }
        end

        should 'pick horizontally when the plate purpose says so' do
          @target_purpose.update!(cherrypick_direction: 'row')
          @expected =
            (1..12).map do |index|
              request = @requests[@asset_shape.vertical_to_horizontal(index, @requests.size) - 1]
              [request.id, request.asset.plate.human_barcode, request.asset.map.description]
            end
        end

        should 'load only the most recent plate barcode' do
          fluidx_barcode = 'FB11111111'
          Barcode.create!(asset: @requests.first.asset.plate, barcode: fluidx_barcode, format: 'fluidx_barcode')
          @expected = @requests.map { |request| [request.id, fluidx_barcode, request.asset.map_description] }
        end
      end

      should 'error when the robot has no beds' do
        robot = mock('robot')
        robot.stubs(:max_beds).returns(0)

        assert_raises(StandardError) do
          @task.pick_new_plate(nil, nil, robot, nil, PlatePurpose.new(asset_shape: @asset_shape, size: 12))
        end
      end
    end
  end
end
