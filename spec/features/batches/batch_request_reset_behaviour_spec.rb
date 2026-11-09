# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Resetting batches and their requests' do
  include BatchFeatureHelpers

  it 'returns all five removed Cherrypick requests to the pipeline inbox' do
    user = create(:admin, login: 'John Smith', first_name: 'John', last_name: 'Doe')
    pipeline = create_batch_feature_pipeline('Cherrypick')
    submission_user = create(:user)
    assets = Array.new(5) do
      plate = create(:plate, :scanned_into_lab)
      create(:well, :scanned_into_lab, plate: plate, map_id: Map.map_96wells.first.id)
    end
    create(
      :linear_submission,
      study: create(:study),
      project: create(:project),
      user: submission_user,
      assets: assets,
      request_types: [pipeline.request_types.active.first!.id],
      request_options: nil
    ).submission.built!
    job_count = Delayed::Job.count
    expect(job_count).to be_positive
    process_batch_submission_jobs(job_count)
    requests = pipeline.requests.ready_in_storage.to_a
    expect(requests.size).to eq(5)
    batch = Batch.create!(pipeline: pipeline, user: submission_user, requests: requests)
    batch.update!(state: 'pending')
    batch.requests.each { |request| request.update!(state: 'pending') }

    login_user(user)
    visit_batch_pipeline(pipeline)
    click_link 'View pending batch 1'
    expect(page).to have_text('Fail batch or requests Batches can not be failed when pending')
    click_link 'Select Plate Template'
    click_link 'Fail batch'
    (1..5).each { |index| check "Remove request #{index}" }
    select 'Other', from: 'Select failure reason'
    click_button 'Fail selected requests'
    expect(page).to have_text('removed.')

    inbox_requests = pipeline.requests.ready_in_storage.full_inbox.to_a
    expect(inbox_requests.size).to eq(5)
    expect(inbox_requests.map(&:id)).to match_array(requests.map(&:id))
    expect(batch.reload.requests).to be_empty
    expect(inbox_requests.map(&:state)).to all(eq('pending'))
  end
end
