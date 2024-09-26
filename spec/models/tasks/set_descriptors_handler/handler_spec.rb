# frozen_string_literal: true

require 'rails_helper'

# This is a very tangled test, as I'm hoping to unhook the current dependencies
# so need to wrap it at its current level of messiness
RSpec.describe Tasks::SetDescriptorsHandler::Handler do
  subject(:handler) { described_class.new(controller:, params:, task:, user:) }

  let(:batch) { create(:batch, request_count: 1) }
  let(:request) { batch.requests.first }
  let(:controller) { instance_double(WorkflowsController) }
  let(:user) { create(:user) }
  let(:task) { instance_double(SetDescriptorsTask, name: 'Step 1', id: 1) }

  describe '#perform' do
    context 'with all requests selected' do
      let(:params) do
        { batch_id: batch.id.to_s, descriptors: { 'key' => 'value ' }, request: { request.id.to_s => 'on' } }
      end

      it 'returns true' do
        expect(handler.perform).to be true
      end

      it 'creates a lab event for the request and batch' do
        expect { handler.perform }.to change(LabEvent, :count).by(2)
      end

      it 'sets attributes on the lab event' do
        handler.perform
        event = request.reload.lab_events.first
        expect(event).to have_attributes(description: 'Step 1', descriptor_hash: { 'key' => 'value ' }, user:)
      end

      it 'sets attributes on the batch event' do
        handler.perform
        event = batch.reload.lab_events.first
        expect(event).to have_attributes(
          description: 'Complete',
          descriptor_hash: {
            'task' => 'Step 1',
            'task_id' => '1'
          },
          user:
        )
      end
    end
  end
end
