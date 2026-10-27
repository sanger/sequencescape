# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::CallbackJob do
  let(:api_application) { create(:api_application, name: ApiApplication::INTEGRATION_HUB_NAME) }
  let(:api_operation) { create(:api_operation, api_application:) }
  let(:url) { 'https://caller.example.com/callback' }

  before { allow(ENV).to receive(:fetch).and_call_original }

  describe 'finding the callback URL' do
    let(:stub) { stub_request(:post, url) }

    before { stub }

    it 'reads the variable named after the application' do
      application = create(:api_application, name: ' my-app (v2) ')
      operation = create(:api_operation, api_application: application)
      allow(ENV).to receive(:fetch).with('MY_APP_V2_CALLBACK_URL', nil).and_return(url)

      described_class.new(operation.id).perform

      expect(stub).to have_been_requested
    end

    it 'raises missing callback URL exception, when it is not set' do
      allow(ENV).to receive(:fetch).with('INTEGRATION_HUB_CALLBACK_URL', nil).and_return(nil)

      expect { described_class.new(api_operation.id).perform }.to raise_error(
                                                                    ApiOperation::Errors::MissingCallbackUrl,
                                                                    'INTEGRATION_HUB_CALLBACK_URL is not set'
                                                                  )
    end

    it 'does not mark the operation delivered' do
      expect(api_operation.reload.response_delivered_at).to be_nil
    end

  end

  context 'when the application has a callback URL' do
    before { allow(ENV).to receive(:fetch).with('INTEGRATION_HUB_CALLBACK_URL', nil).and_return(url) }

    it 'posts the operation status' do
      stub =
        stub_request(:post, url).with(
          body: {
            external_id: api_operation.external_id,
            operation_type: api_operation.operation_type,
            status: api_operation.status
          },
          headers: { 'Content-Type' => 'application/json' }
        ).to_return(status: 200)

      described_class.new(api_operation.id).perform

      expect(stub).to have_been_requested
    end

    it 'posts the operation status with error details when present' do # rubocop:disable RSpec/ExampleLength
      errors = [
        Api::V2::Sapio::Errors::FieldValueConflict.new(:uuid, 'labware.uuid'),
        Api::V2::Sapio::Errors::MissingUuid.new
      ]
      api_operation.update!(status: ApiOperation.statuses[:completed_with_errors], error_details: errors)

      stub =
        stub_request(:post, url).with(
          body: {
            external_id: api_operation.external_id,
            operation_type: api_operation.operation_type,
            status: ApiOperation.statuses[:completed_with_errors],
            error_details: api_operation.error_details
          },
          headers: { 'Content-Type' => 'application/json' }
        ).to_return(status: 200)

      described_class.new(api_operation.id).perform

      expect(stub).to have_been_requested
    end

    it 'raises on a non-success response so the job is retried' do
      stub_request(:post, url).to_return(status: 500)

      expect { described_class.new(api_operation.id).perform }.to raise_error(
        ApiOperation::Errors::DeliveryFailed,
        /HTTP 500/
      )
    end

    it 'updates api_operation with response_delivered_at' do
      stub_request(:post, url)
      described_class.new(api_operation.id).perform

      expect(api_operation.reload.response_delivered_at).not_to be_nil
    end
  end



  describe 'retrying a failed delivery' do
    let(:worker) { Delayed::Worker.new(quiet: true) }
    let(:delayed_job) { Delayed::Job.last }

    before do
      allow(ENV).to receive(:fetch).with('INTEGRATION_HUB_CALLBACK_URL', nil).and_return(url)
      Delayed::Job.delete_all
      Delayed::Job.enqueue(described_class.new(api_operation.id))
    end

    it 'reschedules the job and records the error when the response is not a success' do
      stub_request(:post, url).to_return(status: 500)

      worker.work_off

      expect(delayed_job).to have_attributes(
        attempts: 1,
        last_error: /failed with HTTP 500/,
        run_at: be > Time.current
      )
    end

    it 'delivers on a later attempt once the calling system recovers' do
      stub_request(:post, url).to_return({ status: 500 }, { status: 200 })

      worker.work_off
      travel_to(delayed_job.run_at + 1.second) { worker.work_off }

      expect([Delayed::Job.count, api_operation.reload.response_delivered_at.nil?]).to eq([0, false])
    end
  end
end
