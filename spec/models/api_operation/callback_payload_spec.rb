# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CallbackPayload do
  subject(:payload) { described_class.new(api_operation).to_h }

  let(:api_operation) { create(:api_operation, status:, error_details:) }
  let(:error_details) { nil }
  let(:identifiers) do
    { operation_type: 'reception_and_work_order', external_id: api_operation.external_id }
  end

  context 'when every task completed' do
    let(:status) { 'work_order_completed' }

    it 'has the type, request ID and status, without errors' do
      expect(payload).to eq(identifiers.merge(status: 'work_order_completed'))
    end
  end

  context 'when a task failed' do
    let(:status) { 'work_order_failed' }
    let(:errors) { [{ 'pointer' => '/work_order/cost_code', 'detail' => 'cost_code is required' }] }
    let(:error_details) { { 'task' => 'work_order', 'errors' => errors } }

    it 'adds only the errors' do
      expect(payload).to eq(identifiers.merge(status: 'work_order_failed', errors: errors))
    end
  end
end
