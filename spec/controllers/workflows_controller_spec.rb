# frozen_string_literal: true

require 'rails_helper'

# Tests for the batch edit flow through WorkflowsController#stage, in particular
# the handling of Request::SampleCompoundAliquotTransfer::Error which is raised
# when the source samples of a sequencing request cannot be combined into a
# compound sample (eg. they share the same tag1/tag2/tag_depth combination).
# See https://github.com/sanger/sequencescape/issues/6099
RSpec.describe WorkflowsController do
  let(:current_user) { create(:user) }
  let(:pipeline) { create(:sequencing_pipeline) }
  let(:workflow) { pipeline.workflow }
  let!(:task) do
    create(
      :set_descriptors_task,
      name: 'Specify Dilution Volume',
      workflow: workflow,
      per_item: true,
      descriptor_attributes: [{ kind: 'Text', sorter: 0, name: 'Concentration' }]
    )
  end
  let(:batch) { create(:batch, pipeline: pipeline) }
  let(:tags) { create_list(:tag, 2) }
  let(:study) { create(:study) }
  let(:project) { create(:project) }
  let(:source) { create(:receptacle) }
  let(:destination) { create(:receptacle) }
  let(:aliquot1_tag_depth) { 1 }
  let(:aliquot2_tag_depth) { 1 }
  let!(:aliquot1) do
    create(
      :aliquot,
      sample: create(:sample),
      tag: tags[0],
      tag2: tags[1],
      tag_depth: aliquot1_tag_depth,
      study: study,
      project: project,
      library_type: 'Standard',
      library_id: 54,
      receptacle: source
    )
  end
  let!(:aliquot2) do
    create(
      :aliquot,
      sample: create(:sample),
      tag: tags[0],
      tag2: tags[1],
      tag_depth: aliquot2_tag_depth,
      study: study,
      project: project,
      library_type: 'Standard',
      library_id: 54,
      receptacle: source
    )
  end
  let(:sequencing_request) do
    create(:sequencing_request, asset: source, target_asset: destination, initial_study_id: study.id)
  end

  before { batch.requests << sequencing_request }

  def post_to_stage
    post :stage,
         params: {
           workflow_id: workflow.id,
           id: 0,
           batch_id: batch.id,
           next_stage: '1',
           descriptors: { 'Concentration' => '1.0' },
           request: { sequencing_request.id.to_s => 'on' }
         },
         session: { user: current_user.id }
  end

  describe '#stage' do
    context 'when the source samples share the same tag1, tag2 and tag_depth' do
      it 'does not raise an error' do
        expect { post_to_stage }.not_to raise_error
      end

      it 'displays the compound sample error to the user', :aggregate_failures do
        post_to_stage
        expect(flash[:alert]).to include('Unable to complete this task')
        expect(flash[:alert]).to include("duplicate 'tag depth'")
      end

      it 're-renders the task page instead of redirecting' do
        post_to_stage
        expect(response).to have_http_status(:ok)
      end

      it 'rolls back the batch and request state changes', :aggregate_failures do
        post_to_stage
        expect(batch.reload).to be_pending
        expect(sequencing_request.reload).to be_pending
      end
    end

    context 'when the source samples can be distinguished by tag depth' do
      let(:aliquot2_tag_depth) { 2 }

      it 'completes the task without showing an error' do
        post_to_stage
        expect(flash[:alert]).to be_nil
      end

      it 'starts the batch and the request', :aggregate_failures do
        post_to_stage
        expect(batch.reload).to be_started
        expect(sequencing_request.reload).to be_started
      end

      it 'redirects to the finish batch page' do
        post_to_stage
        expect(response).to redirect_to(finish_batch_path(batch))
      end
    end
  end
end
