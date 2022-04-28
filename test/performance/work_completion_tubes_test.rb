# frozen_string_literal: true

require 'test_helper'
require 'rails/performance_test_help'

class WorkCompletionTubesTest < ActionDispatch::PerformanceTest
  self.profile_options = { runs: 1, metrics: %i[wall_time memory], formats: [:flat] }

  # THis setup mimic the end of the GBS pipeline.
  # rubocop:todo Metrics/PerceivedComplexity, Metrics/AbcSize
  def setup # rubocop:todo Metrics/CyclomaticComplexity
    @user = create :user

    tested_wells = 2
    input_plate_1 = create :input_plate, well_count: tested_wells, well_factory: :tagged_well
    input_plate_2 = create :input_plate, well_count: tested_wells, well_factory: :tagged_well
    input_plate_3 = create :input_plate, well_count: tested_wells, well_factory: :tagged_well
    input_plate_4 = create :input_plate, well_count: tested_wells, well_factory: :tagged_well

    library_request_type = create :library_request_type
    submission_request_types = [library_request_type]
    target_submission_1 =
      create :library_submission, assets: input_plate_1.wells, request_types: submission_request_types
    target_submission_2 =
      create :library_submission, assets: input_plate_2.wells, request_types: submission_request_types
    target_submission_3 =
      create :library_submission, assets: input_plate_3.wells, request_types: submission_request_types
    target_submission_4 =
      create :library_submission, assets: input_plate_4.wells, request_types: submission_request_types
    decoy_submission = create :library_submission, assets: input_plate_1.wells, request_types: submission_request_types

    input_plate_1.wells.each do |well|
      next if well.aliquots.empty?

      create :library_request,
             request_type: library_request_type,
             asset: well,
             submission: target_submission_1,
             state: 'started'
      create :library_request,
             request_type: library_request_type,
             asset: well,
             submission: decoy_submission,
             state: 'started'
    end
    input_plate_2.wells.each do |well|
      next if well.aliquots.empty?

      create :library_request,
             request_type: library_request_type,
             asset: well,
             submission: target_submission_2,
             state: 'started'
    end
    input_plate_3.wells.each do |well|
      next if well.aliquots.empty?

      create :library_request,
             request_type: library_request_type,
             asset: well,
             submission: target_submission_3,
             state: 'started'
    end
    input_plate_4.wells.each do |well|
      next if well.aliquots.empty?

      create :library_request,
             request_type: library_request_type,
             asset: well,
             submission: target_submission_4,
             state: 'started'
    end

    # The decoy submission represents a submission which we don't care about
    # The target plate is the downstream plate we are going to be passing.
    target_plate_1 =
      create :target_plate, parent: input_plate_1, well_count: tested_wells, submission: target_submission_1
    target_plate_2 =
      create :target_plate, parent: input_plate_2, well_count: tested_wells, submission: target_submission_2
    target_plate_3 =
      create :target_plate, parent: input_plate_3, well_count: tested_wells, submission: target_submission_3
    target_plate_4 =
      create :target_plate, parent: input_plate_4, well_count: tested_wells, submission: target_submission_4

    # Build the tube graphs
    tube_1_2 = create :new_stock_multiplexed_library_tube, parents: [target_plate_1, target_plate_2]

    [target_plate_1, target_plate_2].flat_map(&:wells).each do |well|
      create :transfer_request, asset: well, target_asset: tube_1_2
    end

    tube_3 = create :new_stock_multiplexed_library_tube, parents: [target_plate_3]

    target_plate_3.wells.each { |well| create :transfer_request, asset: well, target_asset: tube_3 }

    tube_4 = create :new_stock_multiplexed_library_tube, parents: [target_plate_4]

    target_plate_4.wells.each { |well| create :transfer_request, asset: well, target_asset: tube_4 }

    thirds =
      [tube_1_2, tube_3, tube_4].map do |start|
        second = create :new_stock_multiplexed_library_tube # , parents: [start]
        create :transfer_request, asset: start, target_asset: second
        third = create :new_stock_multiplexed_library_tube # , parents: [second]
        create :transfer_request, asset: second, target_asset: third
        third
      end

    @target_tube = create :multiplexed_library_tube, parents: thirds
    thirds.each { |third| create :transfer_request, asset: third, target_asset: @target_tube }
  end

  # rubocop:enable Metrics/AbcSize, Metrics/PerceivedComplexity

  test 'WorkCompletion.create performance with tubes' do
    Rails.logger.level = 0
    Rails.logger.info('*' * 160)
    ActiveRecord::Base.transaction do
      WorkCompletion.create!(user_id: @user.id, target_id: @target_tube.id, submission_ids: nil)
    end
    Rails.logger.info('=' * 160)
    Rails.logger.level = 2
  end
end
