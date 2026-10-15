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

  it 'gets a uuid when created' do
    api_operation.save!
    expect(api_operation.uuid).to match(/\A\h{8}-\h{4}-\h{4}-\h{4}-\h{12}\z/)
  end
end
