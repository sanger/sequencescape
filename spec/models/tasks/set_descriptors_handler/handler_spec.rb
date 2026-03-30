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
  let(:task) { instance_double(SetDescriptorsTask, name: 'Step 1', id: 1, descriptors: []) }

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
        expect(event).to have_attributes(description: 'Step 1', descriptor_hash: { 'key' => 'value ' }, user: user)
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
          user: user
        )
      end
    end

    # The handler delegates validation entirely to Descriptor#validate_value.
    # Full Date validation rules are covered in spec/models/descriptor_spec.rb.
    context 'when a descriptor returns no errors' do
      let(:passing_descriptor) { instance_double(Descriptor, name: 'OTR carrier expiry') }
      let(:task) { instance_double(SetDescriptorsTask, name: 'Step 1', id: 1, descriptors: [passing_descriptor]) }
      let(:params) do
        {
          batch_id: batch.id.to_s,
          descriptors: { 'OTR carrier expiry' => '2026-06-01' },
          request: { request.id.to_s => 'on' }
        }
      end

      before { allow(passing_descriptor).to receive(:validate_value).with('2026-06-01').and_return([]) }

      it 'returns true' do
        expect(handler.perform).to be true
      end
    end

    context 'when a descriptor returns a validation error' do
      let(:error_message) { "'not-a-date' is not a valid date for OTR carrier expiry (expected YYYY-MM-DD)" }
      let(:failing_descriptor) { instance_double(Descriptor, name: 'OTR carrier expiry') }
      let(:task) { instance_double(SetDescriptorsTask, name: 'Step 1', id: 1, descriptors: [failing_descriptor]) }
      let(:params) do
        {
          batch_id: batch.id.to_s,
          descriptors: { 'OTR carrier expiry' => 'not-a-date' },
          request: { request.id.to_s => 'on' }
        }
      end

      before { allow(failing_descriptor).to receive(:validate_value).with('not-a-date').and_return([error_message]) }

      it 'returns [false, error_message]' do
        expect(handler.perform).to eq([false, error_message])
      end

      it 'does not create any lab events' do
        expect { handler.perform }.not_to change(LabEvent, :count)
      end
    end
  end
end
