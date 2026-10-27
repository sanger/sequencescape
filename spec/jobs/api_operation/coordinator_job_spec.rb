# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CoordinatorJob do
  let(:api_operation) { create(:api_operation) }

  def perform
    described_class.new(api_operation.id).perform
  end

  context 'when reception is disabled', :sapio_reception_disabled do
    it 'logs that the operation is ready for processing' do
      allow(Rails.logger).to receive(:info)
      perform
      expect(Rails.logger).to have_received(:info)
        .with("ApiOperation #{api_operation.uuid} is ready for processing")
    end

    it 'does not run the reception' do
      allow(ApiOperation::Reception).to receive(:new)
      perform
      expect(ApiOperation::Reception).not_to have_received(:new)
    end

    it 'leaves the operation queued' do
      perform
      expect(api_operation.reload.status).to eq('queued')
    end
  end

  context 'when reception is enabled', :sapio_reception_enabled do
    let(:errors) { [] }
    let(:reception) { instance_double(ApiOperation::Reception, call: errors) }

    before do
      allow(ApiOperation::Reception).to receive(:new).and_return(reception)
    end

    it 'runs the reception for the operation' do
      perform
      expect(ApiOperation::Reception).to have_received(:new)
        .with(api_operation)
    end

    it 'records the reception as completed' do
      perform
      expect(api_operation.reload.status).to eq('reception_completed')
    end

    it 'adds a completed event' do
      perform
      expect(api_operation.events.pluck(:task, :outcome))
        .to eq([%w[reception completed]])
    end

    context 'when the reception finds errors' do
      let(:errors) { [{ pointer: '/labware/0', detail: 'Barcode in use' }] }

      it 'records the reception as failed' do
        perform
        expect(api_operation.reload.status).to eq('reception_failed')
      end

      it 'stores the errors' do
        perform
        expect(api_operation.reload.error_details).to eq(
          'task' => 'reception',
          'errors' => [{ 'pointer' => '/labware/0',
                         'detail' => 'Barcode in use' }]
        )
      end
    end

    context 'when the reception raises' do
      before do
        allow(reception).to receive(:call).and_raise(ActiveRecord::Deadlocked)
      end

      it 'passes the error on' do
        expect { perform }.to raise_error(ActiveRecord::Deadlocked)
      end

      it 'leaves the operation queued' do
        suppress(ActiveRecord::Deadlocked) { perform }
        expect(api_operation.reload.status).to eq('queued')
      end

      it 'adds no event' do
        suppress(ActiveRecord::Deadlocked) { perform }
        expect(api_operation.events).to be_empty
      end
    end

    context 'when the reception has already completed' do
      before { api_operation.complete_task!('reception') }

      it 'does not run it again' do
        perform
        expect(ApiOperation::Reception).not_to have_received(:new)
      end
    end

    context 'when the reception has already failed' do
      before { api_operation.fail_task!('reception', [{ detail: 'Failed' }]) }

      it 'does not run it again' do
        perform
        expect(ApiOperation::Reception).not_to have_received(:new)
      end
    end

    it 'runs the reception once when the job runs twice' do
      2.times { perform }
      expect(reception).to have_received(:call).once
    end

    it 'locks the operation before running its task' do
      allow(ApiOperation).to receive(:find).and_return(api_operation)
      allow(api_operation).to receive(:lock!).and_call_original
      perform
      expect(api_operation).to have_received(:lock!).at_least(:once)
    end
  end
end
