# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CoordinatorJob do
  let(:api_operation) { create(:api_operation) }

  it 'logs that the operation is ready for processing' do
    allow(Rails.logger).to receive(:info)
    described_class.new(api_operation.id).perform
    expect(Rails.logger).to have_received(:info)
      .with("ApiOperation #{api_operation.uuid} is ready for processing")
  end
end
