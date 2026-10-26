# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CoordinatorJob do
  let(:api_operation) { create(:api_operation) }

  context 'when reception is disabled', :sapio_reception_disabled do
    it 'logs that the operation is ready for processing' do
      allow(Rails.logger).to receive(:info)
      described_class.new(api_operation.id).perform
      expect(Rails.logger).to have_received(:info)
        .with("ApiOperation #{api_operation.uuid} is ready for processing")
    end

    it 'does not run the reception' do
      allow(ApiOperation::Reception).to receive(:new)
      described_class.new(api_operation.id).perform
      expect(ApiOperation::Reception).not_to have_received(:new)
    end
  end

  context 'when reception is enabled', :sapio_reception_enabled do
    let(:reception) { instance_double(ApiOperation::Reception, call: nil) }

    before do
      allow(ApiOperation::Reception).to receive(:new)
        .with(api_operation).and_return(reception)
    end

    it 'runs the reception for the operation' do
      described_class.new(api_operation.id).perform
      expect(reception).to have_received(:call)
    end
  end
end
