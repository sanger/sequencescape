# frozen_string_literal: true

shared_context 'a limber target plate with submissions' do |library_state = 'started'|
  # A note on improving speed: before(:context) could be used instead of before(:each) to ensure these elements only get
  # built once. This will speed things up, but is discouraged. You can't use let in a before(:context) so instance
  # variables would need to be set instead.
  #
  let(:tested_wells) { 3 }
  let(:requests_per_well) { 1 }

  # The input plate represents the plate going into the pipeline
  # from which the requests will be made.
  let(:input_plate) { create :input_plate, well_count: tested_wells, well_factory: :tagged_well }
  let(:library_request_type) { create :library_request_type }
  let(:multiplex_request_type) { create :multiplex_request_type }
  let(:submission_request_types) { [library_request_type, multiplex_request_type] }

  # The target submission represents the submission we're about to pass requests for
  let(:target_submission) do
    create :library_submission, assets: input_plate.wells, request_types: submission_request_types
  end
  let(:order) { target_submission.orders.first }

  # The decoy submission represents a submission which we don't care about
  let(:decoy_submission) do
    create :library_submission, assets: input_plate.wells, request_types: submission_request_types
  end

  # The target plate is the downstream plate we are going to be passing.
  let(:target_plate) do
    create :target_plate, parent: input_plate, well_count: tested_wells, submission: target_submission
  end

  # And now we have a few helpers to make the tests more readable
  let(:library_requests) { target_submission.requests.where(request_type_id: library_request_type.id) }
  let(:multiplex_requests) { target_submission.requests.where(request_type_id: multiplex_request_type.id) }
  let(:decoy_submission_requests) { decoy_submission.requests.where(request_type_id: library_request_type.id) }

  let(:build_library_requests) do
    input_plate.wells.each do |well|
      create_list(
        :library_request,
        requests_per_well,
        request_type: library_request_type,
        asset: well,
        submission: target_submission,
        state: library_state,
        order:
      )
      create :library_request,
             request_type: library_request_type,
             asset: well,
             submission: decoy_submission,
             state: library_state
    end
  end

  # Build the requests we'll use. The order here is important, as submissions depend on it for finding the
  # next request in a submission
  before do
    build_library_requests
    submission_request_types[1..].each do |downstream_type|
      input_plate.wells.count.times do
        create_list :multiplex_request, requests_per_well, request_type: downstream_type, submission: target_submission
        create :multiplex_request, request_type: downstream_type, submission: decoy_submission
      end
    end
  end
end
