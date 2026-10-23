# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WorkflowsController do
  let(:user) { create(:admin) }
  let(:pipeline) { create(:pipeline) }
  let(:batch) { pipeline.batches.create! }
  let(:workflow) { pipeline.workflow }
  let(:task) do
    create(:task, workflow: workflow, sorted: 0, sti_type: 'SetDescriptorsTask', lab_activity: true)
  end
  let(:error_message) do
    "#{CompoundAliquot::DUPLICATE_TAG_DEPTH_ERROR_MSG}: [\"sample-one\", \"sample-two\"]"
  end
  let(:stage_params) do
    { workflow_id: workflow.id, batch_id: batch.id, id: 0, next_stage: 'true', commit: 'Update' }
  end

  before do
    task
    session[:user] = user.id
    allow(controller).to receive(:start_batch).and_raise(Request::SampleCompoundAliquotTransfer::Error, error_message)
  end

  # Keep the controller transaction independent of the test's enclosing transaction
  # so exceptions exercise the actual rollback behavior.
  around do |example|
    ActiveRecord::Base.transaction(requires_new: true, joinable: false) do
      example.run
      raise ActiveRecord::Rollback
    end
  end

  describe 'POST #stage with invalid compound aliquots' do
    it 'propagates the compound-aliquot validation error' do
      expect { post :stage, params: stage_params }
        .to raise_error(Request::SampleCompoundAliquotTransfer::Error, error_message)
    end

    it 'propagates the error when continuing without an Update commit' do
      expect { post :stage, params: stage_params.except(:commit) }
        .to raise_error(Request::SampleCompoundAliquotTransfer::Error, error_message)
    end

    it 'rolls back task events and leaves the batch pending', :aggregate_failures do
      batch
      expect { post :stage, params: stage_params }
        .to raise_error(Request::SampleCompoundAliquotTransfer::Error, error_message)

      expect(LabEvent.count).to eq(0)
      expect(batch.reload).to be_pending
    end

    it 'does not hide unrelated errors' do
      allow(controller).to receive(:start_batch).and_raise(StandardError, 'Unexpected failure')

      expect { post :stage, params: stage_params }.to raise_error(StandardError, 'Unexpected failure')
    end

    context 'when a later request has clashing tag sequences' do
      let(:study) { create(:study) }
      let(:project) { create(:project) }
      let(:tag) { create(:tag, oligo: 'ACGT') }
      let(:duplicate_tag) { create(:tag, oligo: tag.oligo) }
      let(:tag2) { create(:tag, oligo: 'TGCA') }
      let(:valid_aliquots) do
        [1, 2].map do |depth|
          create(:aliquot, study: study, project: project, tag: tag, tag2: tag2, tag_depth: depth)
        end
      end
      let(:invalid_aliquots) do
        [tag, duplicate_tag].map do |source_tag|
          create(:aliquot, study: study, project: project, tag: source_tag, tag2: tag2, tag_depth: 1)
        end
      end
      let(:sequencing_requests) do
        [valid_aliquots, invalid_aliquots].map do |aliquots|
          create(
            :sequencing_request,
            asset: create(:receptacle, aliquots:),
            target_asset: create(:receptacle),
            initial_study: study,
            initial_project: project
          )
        end
      end
      let(:stage_params) do
        super().merge(request: sequencing_requests.to_h { |request| [request.id.to_s, 'on'] })
      end

      before do
        sequencing_requests.each_with_index do |request, index|
          batch.batch_requests.create!(request: request, position: index + 1)
        end
        allow(controller).to receive(:start_batch).and_call_original
      end

      it 'propagates the error when the real validation fails' do
        expect { post :stage, params: stage_params }
          .to raise_error(Request::SampleCompoundAliquotTransfer::Error)
      end

      it 'raises the compound-aliquot validation message' do
        expect { post :stage, params: stage_params }.to raise_error(
          Request::SampleCompoundAliquotTransfer::Error,
          /#{Regexp.escape(CompoundAliquot::DUPLICATE_TAG_DEPTH_ERROR_MSG)}/o
        )
      end

      it 'includes the affected sample names in the raised message' do
        sample_names = invalid_aliquots.map { |aliquot| aliquot.sample.name }
        expect { post :stage, params: stage_params }.to raise_error(
          Request::SampleCompoundAliquotTransfer::Error,
          /#{Regexp.escape(sample_names.to_s)}/o
        )
      end

      it 'keeps the batch pending after the failed operation', :aggregate_failures do
        expect { post :stage, params: stage_params }
          .to raise_error(Request::SampleCompoundAliquotTransfer::Error)

        expect(batch.reload).to be_pending
      end

      it 'keeps all sequencing requests pending after the failed operation', :aggregate_failures do
        expect { post :stage, params: stage_params }
          .to raise_error(Request::SampleCompoundAliquotTransfer::Error)

        expect(sequencing_requests.map { |request| request.reload.state }).to eq(%w[pending pending])
      end

      it 'rolls back all lane aliquot transfers, including an earlier valid request', :aggregate_failures do
        expect { post :stage, params: stage_params }
          .to raise_error(Request::SampleCompoundAliquotTransfer::Error)

        expect(sequencing_requests.map { |request| request.target_asset.aliquots.count }).to eq([0, 0])
      end

      it 'rolls back compound sample creation for an earlier valid request', :aggregate_failures do
        expect do
          expect { post :stage, params: stage_params }
            .to raise_error(Request::SampleCompoundAliquotTransfer::Error)
        end.not_to change(Sample, :count)
      end

      it 'rolls back task events created before the validation failure', :aggregate_failures do
        expect do
          expect { post :stage, params: stage_params }
            .to raise_error(Request::SampleCompoundAliquotTransfer::Error)
        end.not_to change(LabEvent, :count)
      end
    end
  end

  describe 'POST #stage when the task returns failure' do
    let(:task_message) { 'Descriptor values are invalid' }

    before do
      allow(Tasks::SetDescriptorsHandler::Handler).to receive(:new).and_wrap_original do |original, *args, **kwargs|
        original.call(*args, **kwargs).tap do |handler|
          allow(handler).to receive(:perform).and_return([false, task_message])
        end
      end
      allow(controller).to receive(:render_set_descriptors_task) do |current_task, _params|
        controller.render plain: current_task.name
      end
    end

    it 'shows the failure message and renders the current task', :aggregate_failures do
      post :stage, params: stage_params

      expect(flash[:alert]).to eq(task_message)
      expect(response).to have_http_status(:ok)
      expect(response.body).to eq(task.name)
    end

    it 'does not start or advance the batch', :aggregate_failures do
      allow(controller).to receive(:start_batch)

      post :stage, params: stage_params

      expect(controller).not_to have_received(:start_batch)
      expect(batch.reload).to be_pending
    end
  end
end
