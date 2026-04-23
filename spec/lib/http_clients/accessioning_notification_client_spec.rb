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
    context 'when requesting the token from the authentication service' do
      let(:cache_key) { 'integration_hub/auth_token' }
      let(:token_response) { { 'access_token' => 'token-123', 'expires_in' => 120 } }

      before do
        # Override top-level stub for these tests
        allow(client).to receive(:auth_token).and_call_original
        Rails.cache.delete(cache_key)
      end

      after do
        Rails.cache.delete(cache_key)
      end

      describe '#get_token_data' do
        it 'returns token data from the auth endpoint' do
          stub_request(:post, configatron.integration_hub.auth_token_url)
            .to_return(status: 200, body: token_response.to_json, headers: { 'Content-Type' => 'application/json' })

          result = client.send(:get_token_data, configatron.integration_hub)

          expect(result).to eq(token_response)
        end

        it 'sends the correct content-type header' do
          stub_request(:post, configatron.integration_hub.auth_token_url)
            .with(headers: { 'Content-Type' => 'application/x-www-form-urlencoded' })

          client.send(:get_token_data, configatron.integration_hub)
          expect(WebMock).to have_requested(:post, configatron.integration_hub.auth_token_url)
        end

        it 'posts client credentials in the request body' do
          stub_request(:post, configatron.integration_hub.auth_token_url)
            .with(
              body: hash_including(
                'grant_type' => 'client_credentials',
                'client_id' => 'test_client_id',
                'client_secret' => 'test_client_secret'
              )
            )

          client.send(:get_token_data, configatron.integration_hub)

          expect(WebMock).to have_requested(:post, configatron.integration_hub.auth_token_url)
        end

        it 'raises a RuntimeError when auth endpoint returns non-success' do
          stub_request(:post, configatron.integration_hub.auth_token_url)
            .to_return(status: 401,
                       body: { error: 'unauthorized' }.to_json,
                       headers: { 'Content-Type' => 'application/json' })

          expect do
            client.send(:get_token_data, configatron.integration_hub)
          end.to raise_error(RuntimeError, /Failed to obtain auth token: 401/)
        end
      end

      describe '#auth_token' do
        it 'returns cached token and does not request a new token' do
          # Mock the cache read to return a value, as caching is disabled in the test environment
          allow(Rails.cache).to receive(:read).with(cache_key).and_return('cached-token')
          allow(client).to receive(:get_token_data).and_raise('get_token_data should not be called')

          token = client.send(:auth_token)

          expect(token).to eq('cached-token')
        end

        it 'fetches token and caches it with shortened ttl' do # rubocop:disable RSpec/ExampleLength
          allow(client).to receive(:get_token_data).and_return(token_response)
          allow(Rails.cache).to receive(:write).and_call_original

          client.send(:auth_token)

          expect(Rails.cache).to have_received(:write).with(
            cache_key,
            'token-123',
            expires_in: 90, # 120 - 30
            race_condition_ttl: 10
          )
        end

        it 'uses minimum ttl of 60 seconds when expires_in is too small' do # rubocop:disable RSpec/ExampleLength
          allow(client).to receive(:get_token_data).and_return(
            { 'access_token' => 'short-lived-token', 'expires_in' => 20 }
          )
          allow(Rails.cache).to receive(:write).and_call_original

          client.send(:auth_token)

          expect(Rails.cache).to have_received(:write).with(
            cache_key,
            'short-lived-token',
            expires_in: 60, # max(20 - 30, 60)
            race_condition_ttl: 10
          )
        end
      end
    end

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
                sample_path: "http://example.sanger.ac.uk/samples/#{sample.id}",
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
