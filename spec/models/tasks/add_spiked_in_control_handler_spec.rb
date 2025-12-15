# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Tasks::AddSpikedInControlHandler do
  subject(:handler) do
    described_class::Handler.new(
      controller:,
      params:,
      task:,
      user:
    )
  end

  let(:controller) { instance_double(WorkflowsController) }
  let(:user) { create(:user) }
  let(:task) { instance_double(AddSpikedInControlTask) }
  let(:params) do
    {
      barcode: nil
    }
  end

  describe '#perform' do
    context 'when no barcodes are provided' do
      it 'returns an error message' do
        result, message = handler.perform
        expect([result,
                message]).to match([false,
                                    'No barcodes provided. Please scan or enter PhiX barcodes before proceeding.'])
      end
    end
  end
end
