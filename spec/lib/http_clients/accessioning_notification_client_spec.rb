# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::AccessioningNotificationClient do
  let(:client) { described_class.new }
  let(:sample) { create(:sample_for_accessioning_with_open_study) }
  let(:message) { 'Accessioning failed due to missing metadata.' }
  let(:failure_groups) { ['Internal validations', 'Invalid sample common name'] }
  let(:notification_id) { 'notification-123' }
  let(:notifications_url) { "https://integration-hub.example.com#{described_class::NOTIFICATIONS_URL}" }

  around do |example|
    configatron_dup = configatron.dup
    configatron.integration_hub.base_url = 'https://integration-hub.example.com'
    configatron.integration_hub.auth_token_url = 'https://auth.example.com/oauth2/token'
    configatron.integration_hub.notifications_api.client_id = 'test_client_id'
    configatron.integration_hub.notifications_api.client_secret = 'test_client_secret'
    example.run
    configatron.reset_to(configatron_dup)
  end

  before do
    allow(client).to receive(:auth_token).and_return('test_bearer_token')
    allow(Rails.logger).to receive(:info).and_call_original
    allow(Rails.logger).to receive(:error).and_call_original
  end

  describe '#create_notification' do
    context 'when the request is made' do
      before do
        stub_request(:post, notifications_url)
          .to_return(
            status: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: { notification_id: }.to_json
          )

        client.create_notification(sample, message, failure_groups)
      end

      let(:expected_payload) do
        {
          channels: [
            {
              type: 'EMAIL',
              recipient: ['PSD_EMAIL'],
              content_type: 'html',
              template_id: 'PSD_EMAIL',
              subject: 'Accessioning Failure Notification',
              fields: {
                study_name: sample.studies_for_accessioning.first.name,
                sample_name: sample.name,
                sample_path: "http://uat.sequencescape.sanger.ac.uk/samples/#{sample.id}",
                accessioning_status_message: 'Accessioning failed due to missing metadata.',
                failure_groups: ['Internal validations', 'Invalid sample common name']
              }
            }
          ],
          priority: 'BATCH',
          aggregator_id: "study-#{sample.studies_for_accessioning.map(&:id).join('-')}"
        }
      end

      it 'sends the correct user-agent header' do
        expect(WebMock).to have_requested(:post, notifications_url)
          .with(headers: { 'User-Agent' => 'Sequencescape Accessioning Notification Client' })
      end

      it 'sends the correct authorization header' do
        expect(WebMock).to have_requested(:post, notifications_url)
          .with(headers: { 'Authorization' => 'Bearer test_bearer_token' })
      end

      it 'sends the correct content-type header' do
        expect(WebMock).to have_requested(:post, notifications_url)
          .with(headers: { 'Content-Type' => 'application/json' })
      end

      it 'sends the correct body' do
        expect(WebMock).to have_requested(:post, notifications_url)
          .with(body: expected_payload)
      end
    end

    context 'when the request succeeds' do
      before do
        stub_request(:post, notifications_url)
          .to_return(
            status: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: { notification_id: }.to_json
          )
      end

      it 'returns the notification_id from the response' do
        expect(client.create_notification(sample, message, failure_groups)).to eq(notification_id)
      end

      it 'logs the creation attempt' do
        client.create_notification(sample, message, failure_groups)
        expect(Rails.logger).to have_received(:info).with(
          "Creating notification for sample '#{sample.name}'"
        )
      end
    end

    context 'when the server returns a 400 client error' do
      before do
        stub_request(:post, notifications_url).to_return(status: 400, body: 'Bad Request')
      end

      it 'raises a Faraday::ClientError' do
        expect { client.create_notification(sample, message, failure_groups) }
          .to raise_error(Faraday::ClientError)
      end

      it 'logs the error' do
        client.create_notification(sample, message, failure_groups)
      rescue Faraday::ClientError
        expect(Rails.logger).to have_received(:error).with(
          /Client error while creating notification': Bad Request/
        )
      end
    end

    context 'when the server returns a 500 server error' do
      before do
        stub_request(:post, notifications_url).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises a Faraday::ServerError' do
        expect { client.create_notification(sample, message, failure_groups) }
          .to raise_error(Faraday::ServerError)
      end

      it 'logs the error' do
        client.create_notification(sample, message, failure_groups)
      rescue Faraday::ServerError
        expect(Rails.logger).to have_received(:error).with(
          /Server error while creating notification': Internal Server Error/
        )
      end
    end

    context 'when the server is unreachable' do
      before do
        stub_request(:post, notifications_url).to_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'raises a Faraday::ConnectionFailed error' do
        expect { client.create_notification(sample, message, failure_groups) }
          .to raise_error(Faraday::ConnectionFailed, 'Connection failed')
      end

      it 'logs the error' do
        client.create_notification(sample, message, failure_groups)
      rescue Faraday::ConnectionFailed
        expect(Rails.logger).to have_received(:error).with(
          /Faraday error while creating notification: Connection failed/
        )
      end
    end
  end
end
