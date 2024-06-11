# frozen_string_literal: true

require 'test_helper'
require 'rails/performance_test_help'

class WorkCompletionsTest < ActionDispatch::PerformanceTest
  self.profile_options = { runs: 1, metrics: %i[wall_time memory], formats: [:flat] }

  def setup # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @user = create(:user)

    tested_wells = 96
    input_plate = create(:input_plate, well_count: tested_wells)
    library_request_type = create(:library_request_type)
    multiplex_request_type = create(:multiplex_request_type)
    submission_request_types = [library_request_type, multiplex_request_type]
    @target_submission = create(:library_submission, assets: input_plate.wells, request_types: submission_request_types)
    decoy_submission = create(:library_submission, assets: input_plate.wells, request_types: submission_request_types)

    # The decoy submission represents a submission which we don't care about
    # The target plate is the downstream plate we are going to be passing.
    @target_plate = create(:target_plate, parent: input_plate, well_count: tested_wells)

    input_plate.wells.each do |well|
      create(:library_request,
             request_type: library_request_type,
             asset: well,
             submission: @target_submission,
             state: 'started')
      create(:library_request,
             request_type: library_request_type,
             asset: well,
             submission: decoy_submission,
             state: 'started')
    end
    submission_request_types[1..].each do |downstream_type|
      input_plate.wells.count.times do
        create(:multiplex_request, request_type: downstream_type, submission: @target_submission)
        create(:multiplex_request, request_type: downstream_type, submission: decoy_submission)
      end
    end
  end

  test 'WorkCompletion.create performance' do
    ActiveRecord::Base.transaction do
      WorkCompletion.create!(user_id: @user.id, target_id: @target_plate.id, submission_ids: [@target_submission.id])
    end
  end
end
