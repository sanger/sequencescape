# frozen_string_literal: true

require 'rails_helper'

# Migrated from features/641709_create_duplicate_SE_pipeline_with_no_controls.feature
describe 'Creating a batch in a sequencing pipeline without controls' do
  let(:user) { create(:admin, login: 'John Smith') }
  let(:pipeline) do
    # The factory always adds a control request type. The column cannot be null,
    # so like the seeds, pipelines without controls use 0, which matches no request type.
    create(:sequencing_pipeline, :with_workflow).tap { |pipeline| pipeline.update!(control_request_type_id: 0) }
  end
  let!(:requests) do
    Array.new(pipeline.workflow.item_limit) do
      create(
        :sequencing_request_with_assets,
        request_type: pipeline.request_types.first,
        asset: create(:library_tube, :scanned_into_lab),
        target_asset: nil,
        submission: create(:submission)
      )
    end
  end

  it 'creates a full batch and shows the first task' do
    login_user(user)
    visit pipeline_path(pipeline)
    expect(page).to have_current_path(pipeline_path(pipeline))

    requests.each { |request| check "Select #{request.asset.human_barcode} for batch" }
    first(:select, 'Action to perform').select('Create Batch')
    first(:button, 'Submit').click

    expect(page).to have_text('Specify Dilution Volume')
    expect(pipeline.reload.control_request_type).to be_nil
    expect(Batch.last.requests).to match_array(requests)
  end
end
