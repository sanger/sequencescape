# frozen_string_literal: true
shared_context 'a limber target plate with submissions' do
  # A note on improving speed: before(:context) could be used instead of before(:each) to ensure these elements only get
  # built once. This will speed things up, but is discouraged. You can't use let in a before(:context) so instance variables
  # would need to be set instead.
  # The input plate represents the plate going into the pipeline
  # from which the requests will be made.
  let(:tested_wells) { 3 }
  let(:input_plate) { create :input_plate, well_count: tested_wells }
  let(:library_request_type) { create :library_request_type }
  let(:multiplex_request_type) { create :multiplex_request_type }

  # The target submission represents the submission we're about to pass requests for
  let(:target_submission) do
    create :library_submission, assets: input_plate.wells, request_types: [library_request_type, multiplex_request_type]
  end
  # The decoy submission represents a submission which we don't care about
  let(:decoy_submission) do
    create :library_submission, assets: input_plate.wells, request_types: [library_request_type, multiplex_request_type]
  end
  # The target plate is the downstream plate we are going to be passing.
  let(:target_plate) { create :target_plate, parent: input_plate, well_count: tested_wells }
  # And now we have a few helpers to make the tests more readable
  let(:library_requests) { target_submission.requests.where(request_type_id: library_request_type.id) }
  let(:multiplex_requests) { target_submission.requests.where(request_type_id: multiplex_request_type.id) }
  let(:decoy_submission_requests) { decoy_submission.requests.where(request_type_id: library_request_type.id) }

  # Build the requests we'll use. The order here is important, as submissions depend on it for finding the
  # next request in a submission
  before(:each) do
    input_plate.wells.each do |well|
      create :library_request, request_type: library_request_type, asset: well, submission: target_submission, state: 'started'
      create :library_request, request_type: library_request_type, asset: well, submission: decoy_submission, state: 'started'
    end
    input_plate.wells.count.times do
      create :multiplex_request, request_type: multiplex_request_type, submission: target_submission
      create :multiplex_request, request_type: multiplex_request_type, submission: decoy_submission
    end
  end
end
