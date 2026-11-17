# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/pipelines_navigation.feature
describe 'Pipeline navigation' do
  include BatchFeatureHelpers

  let(:user) { create(:admin, login: 'user') }
  let(:pipeline) { create(:sequencing_pipeline, :with_workflow) }

  before { login_user(user) }

  # Creates a request in the pipeline inbox, on a library tube that has been scanned into the lab
  def create_inbox_request
    create(
      :sequencing_request_with_assets,
      request_type: pipeline.request_types.first,
      asset: create(:library_tube, :scanned_into_lab),
      target_asset: nil,
      submission: create(:submission)
    )
  end

  def create_batch_from_first_inbox_request
    within('#available-requests') { first('input[type=checkbox]').check }
    first(:button, 'Submit').click
  end

  it 'shows the batch actions on a Cherrypick batch page' do
    batch = create(:batch, pipeline: create_batch_cherrypick_pipeline, state: 'pending', production_state: nil)

    visit batch_path(batch)

    expect(page).to have_text('Edit batch')
    expect(page).to have_text('Select Plate Template')
    expect(page).to have_text('Print worksheet')
  end

  it 'removes the requests from the inbox once they are batched' do
    create_inbox_request

    visit pipeline_path(pipeline)
    create_batch_from_first_inbox_request
    expect(page).to have_text('Specify Dilution Volume')

    visit pipeline_path(pipeline)
    expect(page).to have_text('Last 5')
    expect(pipeline.batches).not_to be_empty
    pipeline.batches.flat_map(&:requests).each do |request|
      expect(page).to have_no_css("#request_#{request.id}")
    end
  end

  it 'shows the inbox and creates a batch from it' do
    create(:batch, pipeline: pipeline, state: 'pending', production_state: nil)
    create_inbox_request

    visit pipeline_path(pipeline)
    expect(page).to have_text('Submission ID')
    expect(page).to have_text('Last 5')
    expect(page).to have_text('View batch')

    create_batch_from_first_inbox_request

    expect(page).to have_text('Edit batch')
    expect(page).to have_text('Specify Dilution Volume')
    expect(page).to have_text('Print worksheet')
  end
end
