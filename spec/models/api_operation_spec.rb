# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation do
  subject(:api_operation) { build(:api_operation) }

  it 'is valid with the factory attributes' do
    expect(api_operation).to be_valid
  end

  it 'belongs to an API application' do
    api_operation.api_application = nil
    expect(api_operation).not_to be_valid
  end

  %i[
    external_id
    operation_type
    payload
    payload_digest
    status
  ].each do |attribute|
    it "requires #{attribute}" do
      api_operation.public_send(:"#{attribute}=", nil)
      expect(api_operation).not_to be_valid
    end
  end

  it 'requires a 64 character payload digest' do
    api_operation.payload_digest = 'abc'
    expect(api_operation).not_to be_valid
  end

  it 'starts as queued' do
    expect(described_class.new.status).to eq('queued')
  end

  it 'starts without a response delivery time' do
    expect(described_class.new.response_delivered_at).to be_nil
  end

  it 'stores the response delivery time' do
    delivered_at = Time.zone.local(2026, 10, 22, 14, 30)
    api_operation.update!(response_delivered_at: delivered_at)
    expect(api_operation.reload.response_delivered_at).to eq(delivered_at)
  end

  it 'stores the payload exactly as given' do
    payload = %({"b": 1, "a": 1.10})
    api_operation.payload = payload
    api_operation.save!
    expect(api_operation.reload.payload).to eq(payload)
  end

  describe '.create_with_job!' do
    let(:attributes) { attributes_for(:api_operation).merge(api_application:) }
    let(:api_application) { create(:api_application) }

    it 'queues a coordinator job for the saved operation' do
      operation = described_class.create_with_job!(**attributes)
      expect(Delayed::Job.last.payload_object)
        .to eq(ApiOperation::CoordinatorJob.new(operation.id))
    end

    it 'queues one job' do
      expect { described_class.create_with_job!(**attributes) }
        .to change(Delayed::Job, :count).by(1)
    end

    context 'when the job is not queued' do
      before do
        allow(Delayed::Job).to receive(:enqueue)
          .and_raise(ActiveRecord::StatementInvalid)
      end

      it 'saves no operation' do
        expect do
          suppress(ActiveRecord::StatementInvalid) do
            described_class.create_with_job!(**attributes)
          end
        end.not_to change(described_class, :count)
      end
    end

    context 'when the operation is not saved' do
      before { described_class.create_with_job!(**attributes) }

      it 'queues no job' do
        expect do
          suppress(ActiveRecord::RecordNotUnique) do
            described_class.create_with_job!(**attributes)
          end
        end.not_to change(Delayed::Job, :count)
      end
    end
  end

  describe 'the unique index on calling system and request ID' do
    let(:existing) { create(:api_operation) }

    it 'rejects a second operation with the same request ID' do
      duplicate = build(:api_operation,
                        api_application: existing.api_application,
                        external_id: existing.external_id)
      expect { duplicate.save! }.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'accepts the same request ID from another calling system' do
      other = build(:api_operation, external_id: existing.external_id)
      expect { other.save! }.not_to raise_error
    end

    it 'accepts another request ID from the same calling system' do
      other = build(:api_operation, api_application: existing.api_application)
      expect { other.save! }.not_to raise_error
    end
  end

  it 'gets a uuid when created' do
    api_operation.save!
    expect(api_operation.uuid).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end

  describe 'statuses' do
    it 'lists the statuses of a combined request' do
      expect(api_operation.statuses)
        .to eq(%w[queued reception_completed reception_failed])
    end

    %w[queued reception_completed reception_failed].each do |status|
      it "accepts #{status}" do
        api_operation.status = status
        expect(api_operation).to be_valid
      end
    end

    it 'rejects a status of a task its type does not run' do
      api_operation.status = 'work_order_completed'
      expect(api_operation).not_to be_valid
    end

    it 'rejects an unknown status' do
      api_operation.status = 'completed'
      expect(api_operation).not_to be_valid
    end

    it 'rejects any status for a type without tasks' do
      api_operation.operation_type = 'unknown'
      expect(api_operation).not_to be_valid
    end
  end

  it 'runs reception first for a combined request' do
    expect(api_operation.next_task).to eq('reception')
  end

  describe 'tasks' do
    subject(:api_operation) { create(:api_operation) }

    let(:errors) do
      [
        { pointer: '/labware/0/receptacles/0/samples/0/study_uuid',
          detail: 'Unknown study' },
        { detail: 'Deadlock found when trying to get lock' }
      ]
    end

    before do
      stub_const('ApiOperation::TASKS',
                 { 'reception_and_work_order' => %w[reception work_order] })
    end

    it 'runs the first task while queued' do
      expect(api_operation.next_task).to eq('reception')
    end

    context 'when a task completes' do
      before { api_operation.complete_task!('reception') }

      it 'records the task as completed' do
        expect(api_operation.reload.status).to eq('reception_completed')
      end

      it 'runs the following task next' do
        expect(api_operation.next_task).to eq('work_order')
      end

      it 'adds a completed event' do
        expect(api_operation.events.pluck(:task, :event))
          .to eq([%w[reception completed]])
      end
    end

    context 'when every task completes' do
      before do
        api_operation.complete_task!('reception')
        api_operation.complete_task!('work_order')
      end

      it 'has no next task' do
        expect(api_operation.next_task).to be_nil
      end

      it 'has an event for each task, in order' do
        expect(api_operation.events.pluck(:task, :event))
          .to eq([%w[reception completed], %w[work_order completed]])
      end
    end

    context 'when a task fails' do
      before { api_operation.fail_task!('reception', errors) }

      it 'records the task as failed' do
        expect(api_operation.reload.status).to eq('reception_failed')
      end

      it 'adds a failed event' do
        expect(api_operation.events.pluck(:task, :event))
          .to eq([%w[reception failed]])
      end

      it 'stores the failed task and its errors' do
        expect(api_operation.reload.error_details).to eq(
          'task' => 'reception',
          'errors' => [
            { 'pointer' => '/labware/0/receptacles/0/samples/0/study_uuid',
              'detail' => 'Unknown study' },
            { 'detail' => 'Deadlock found when trying to get lock' }
          ]
        )
      end

      it 'has the same error details before reloading' do
        expect(api_operation.error_details)
          .to eq(api_operation.reload.error_details)
      end

      it 'has no next task' do
        expect(api_operation.next_task).to be_nil
      end

      it 'rejects completing the failed task' do
        expect { api_operation.complete_task!('reception') }
          .to raise_error(ApiOperation::TaskOrderError)
      end
    end

    it 'rejects completing a task out of order' do
      expect { api_operation.complete_task!('work_order') }
        .to raise_error(ApiOperation::TaskOrderError)
    end

    it 'rejects completing a task twice' do
      api_operation.complete_task!('reception')
      expect { api_operation.complete_task!('reception') }
        .to raise_error(ApiOperation::TaskOrderError)
    end

    it 'rejects failing a task out of order' do
      expect { api_operation.fail_task!('work_order', errors) }
        .to raise_error(ApiOperation::TaskOrderError)
    end

    it 'adds no event for a task out of order' do
      suppress(ApiOperation::TaskOrderError) do
        api_operation.complete_task!('work_order')
      end
      expect(api_operation.events).to be_empty
    end

    context 'when the event cannot be saved' do
      before do
        allow(ApiOperation::Event).to receive(:new)
          .and_raise(ActiveRecord::StatementInvalid)
      end

      it 'keeps the status' do
        suppress(ActiveRecord::StatementInvalid) do
          api_operation.complete_task!('reception')
        end
        expect(api_operation.reload.status).to eq('queued')
      end
    end
  end
end
