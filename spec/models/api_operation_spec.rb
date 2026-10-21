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
    reception_status
    work_order_status
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

  it 'starts with a pending reception status' do
    expect(described_class.new.reception_status).to eq('pending')
  end

  it 'starts with a pending work order status' do
    expect(described_class.new.work_order_status).to eq('pending')
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

  describe '#status' do
    it 'is queued when neither task has started' do
      expect(api_operation.status).to eq('queued')
    end

    it 'is processing once reception has started' do
      api_operation.reception_status = 'started'
      expect(api_operation.status).to eq('processing')
    end

    it 'is processing once the work order has started' do
      api_operation.work_order_status = 'started'
      expect(api_operation.status).to eq('processing')
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
end
