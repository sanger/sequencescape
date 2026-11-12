# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/pipelines_navigation.feature
describe 'Pipeline navigation' do
  include BatchFeatureHelpers
  include ClusterFormationPipelineHelpers

  let(:user) { create(:admin, login: 'user') }
  let(:pipeline) { create_cluster_formation_pipeline('Cluster formation PE') }

  before { login_user(user) }

  def create_batch_from_first_request
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
    create_cluster_formation_request(pipeline)

    visit pipeline_path(pipeline)
    create_batch_from_first_request
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
    create_cluster_formation_request(pipeline)

    visit pipeline_path(pipeline)
    expect(page).to have_text('Submission ID')
    expect(page).to have_text('Last 5')
    expect(page).to have_text('View batch')

    create_batch_from_first_request

    expect(page).to have_text('Edit batch')
    expect(page).to have_text('Specify Dilution Volume')
    expect(page).to have_text('Print worksheet')
  end
end
