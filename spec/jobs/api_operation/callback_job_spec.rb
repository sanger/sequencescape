# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CallbackJob do
  subject(:job) { described_class.new(api_operation.id) }

  let(:api_operation) { create(:api_operation, status: 'work_order_completed') }
  let(:client) { instance_double(HTTPClients::ApiOperationCallbackClient, deliver: nil) }

  before { allow(HTTPClients::ApiOperationCallbackClient).to receive(:new).and_return(client) }

  describe '#perform' do
    it 'sends the operation outcome' do
      job.perform
      expect(client).to have_received(:deliver).with(ApiOperation::CallbackPayload.new(api_operation).to_h)
    end

    it 'sets the delivery timestamp once acknowledged' do
      expect { job.perform }.to change { api_operation.reload.response_delivered_at }.from(nil)
    end

    context 'when the delivery fails' do
      before { allow(client).to receive(:deliver).and_raise(Faraday::TimeoutError) }

      it 'raises, so that Delayed Job retries' do
        expect { job.perform }.to raise_error(Faraday::TimeoutError)
      end

      it 'records each failed run as a failed callback event' do
        2.times { suppress(Faraday::TimeoutError) { job.perform } }
        expect(api_operation.events.pluck(:task, :outcome)).to eq([%w[callback failed]] * 2)
      end

      it 'leaves the status as it was' do
        suppress(Faraday::TimeoutError) { job.perform }
        expect(api_operation.reload.status).to eq('work_order_completed')
      end

      it 'leaves the timestamp unset' do
        suppress(Faraday::TimeoutError) { job.perform }
        expect(api_operation.reload.response_delivered_at).to be_nil
      end

      it 'does not run any task again' do
        allow(ApiOperation::Task).to receive(:for)
        suppress(Faraday::TimeoutError) { job.perform }
        expect(ApiOperation::Task).not_to have_received(:for)
      end
    end

    context 'when no callback URL is configured' do
      before do
        allow(client).to receive(:deliver).and_raise(HTTPClients::ApiOperationCallbackClient::NotConfigured)
        allow(ExceptionNotifier).to receive(:notify_exception)
      end

      it 'records a failed callback event' do
        job.perform
        expect(api_operation.events.pluck(:task, :outcome)).to eq([%w[callback failed]])
      end

      it 'does not raise, so Delayed Job does not retry' do
        expect { job.perform }.not_to raise_error
      end

      it 'notifies PSD' do
        job.perform
        expect(ExceptionNotifier).to have_received(:notify_exception)
      end

      it 'leaves the delivery timestamp unset' do
        job.perform
        expect(api_operation.reload.response_delivered_at).to be_nil
      end
    end

    context 'when the outcome was already delivered' do
      before { api_operation.update!(response_delivered_at: 1.hour.ago) }

      it 'sends nothing' do
        job.perform
        expect(client).not_to have_received(:deliver)
      end

      it 'keeps the timestamp' do
        expect { job.perform }.not_to(change { api_operation.reload.response_delivered_at })
      end
    end

    context 'when the operation has not finished' do
      let(:api_operation) { create(:api_operation, status: 'reception_completed') }

      it 'sends nothing' do
        job.perform
        expect(client).not_to have_received(:deliver)
      end
    end
  end

  describe 'retries' do
    let(:now) { Time.zone.local(2026, 10, 29, 12) }

    it 'waits 30 seconds, doubling the wait after each failed run, up to an hour' do
      waits = (1...described_class::MAX_RUNS).map { (job.reschedule_at(now, it) - now).seconds }
      expect(waits).to eq([30.seconds, 1.minute, 2.minutes, 4.minutes, 8.minutes, 16.minutes, 32.minutes, 1.hour,
                           1.hour])
    end

    it 'allows MAX_RUNS runs' do
      expect(job.max_attempts).to eq(described_class::MAX_RUNS)
    end
  end

  describe '#failure' do
    let(:delayed_job) { instance_double(Delayed::Job, error: RuntimeError.new('boom'), last_error: 'boom') }

    before do
      allow(ExceptionNotifier).to receive(:notify_exception)
      job.failure(delayed_job)
    end

    it 'notifies PSD' do
      expect(ExceptionNotifier).to have_received(:notify_exception)
        .with(delayed_job.error, data: hash_including(api_operation_id: api_operation.id))
    end

    it 'leaves the delivery timestamp unset' do
      expect(api_operation.reload.response_delivered_at).to be_nil
    end
  end
end
