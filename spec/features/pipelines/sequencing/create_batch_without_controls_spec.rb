# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/641709_create_duplicate_SE_pipeline_with_no_controls.feature
describe 'Creating a batch in the Cluster formation SE (no controls) pipeline' do
  include ClusterFormationPipelineHelpers

  let(:user) { create(:admin, login: 'John Smith') }
  let(:pipeline) { create_cluster_formation_pipeline('Cluster formation SE (no controls)') }
  let!(:requests) { Array.new(pipeline.workflow.item_limit) { create_cluster_formation_request(pipeline) } }

  it 'creates a batch of eight requests and shows the first task' do
    login_user(user)
    visit pipeline_path(pipeline)
    expect(page).to have_current_path(pipeline_path(pipeline))

    requests.each { |request| check "Select #{request.asset.human_barcode} for batch" }
    first(:select, 'Action to perform').select('Create Batch')
    first(:button, 'Submit').click

    expect(page).to have_text('Specify Dilution Volume')
    expect(Batch.last.requests).to include(*requests)
  end
end
