# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::AccessioningNotificationClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_conn) do
    Faraday.new(url: 'http://example.com') do |f|
      f.response :raise_error
      f.response :json
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new }
  let(:sample) { create(:sample_for_accessioning_with_open_study) }
  let(:message) { 'Accessioning failed due to missing metadata.' }
  let(:failure_groups) { ['Internal validations', 'Invalid sample common name'] }
  let(:notification_id) { 'notification-123' }

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
    allow(client).to receive_messages(conn: test_conn, auth_token: 'test_bearer_token')
    allow(Rails.logger).to receive(:info).and_call_original
    allow(Rails.logger).to receive(:error).and_call_original
  end

  after do
    Faraday.default_connection = nil # remove any stubs after each test
  end

  describe '#conn' do
    # Use a fresh client without stubbed conn for these tests
    let(:actual_client) { described_class.new }

    before { allow(actual_client).to receive(:auth_token).and_return('token') }

    it 'returns a Faraday connection with the configured base URL' do
      expect(actual_client.conn.url_prefix.to_s).to eq('https://integration-hub.example.com/')
    end

    it 'sets the correct User-Agent header' do
      expect(actual_client.conn.headers).to include(
        'User-Agent' => 'Sequencescape Accessioning Notification Client'
      )
    end

    it 'uses a proxy if configured' do
      allow(actual_client).to receive(:proxy).and_return('http://proxy.example.com')
      actual_client.conn
      expect(actual_client).to have_received(:proxy)
    end
  end

  describe '#create_notification' do
    context 'when the request succeeds' do
      before do
        stubs.post(described_class::NOTIFICATIONS_URL) do
          [201, { 'Content-Type' => 'application/json' }, { 'notification_id' => notification_id }.to_json]
        end
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
        stubs.post(described_class::NOTIFICATIONS_URL) { [400, {}, 'Bad Request'] }
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
        stubs.post(described_class::NOTIFICATIONS_URL) { [500, {}, 'Internal Server Error'] }
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
        stubs.post(described_class::NOTIFICATIONS_URL) { raise Faraday::ConnectionFailed, 'Connection failed' }
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

    context 'when inspecting the outgoing request payload' do
      # before do
      #   stubs.post(described_class::NOTIFICATIONS_URL) do
      #     [201, { 'Content-Type' => 'application/json' }, { 'notification_id' => notification_id }.to_json]
      #   end
      # end

      before do
        puts "Stubbing POST request to http://example.com#{described_class::NOTIFICATIONS_URL} with WebMock"
        stub_request(:post, "http://example.com#{described_class::NOTIFICATIONS_URL}")
          .to_return(
            status: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: { 'notification_id' => notification_id }.to_json
          )

        client.create_notification(sample, message, failure_groups)
      end

      it 'posts to the notifications URL with the correct payload shape' do
        request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
        body = JSON.parse(request.body)

        expect(body).to include(
          'priority' => described_class::PRIORITY,
          'channels' => [
            a_hash_including(
              'subject' => described_class::SUBJECT,
              'fields' => a_hash_including(
                'accessioning_status_message' => message,
                'failure_groups' => failure_groups,
                'sample_name' => sample.name
              )
            )
          ]
        )
      end

      it 'sends a Bearer authorization header' do
        request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
        expect(request.headers['Authorization']).to eq('Bearer test_bearer_token')
      end

      it 'sends a JSON Content-Type header' do
        request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
        expect(request.headers['Content-Type']).to match(%r{application/json})
      end

      it 'sets the aggregator_id based on the sample studies' do
        study_ids = sample.studies_for_accessioning.map(&:id).join('-')
        request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last
        body = JSON.parse(request.body)
        expect(body['aggregator_id']).to eq("study-#{study_ids}")
      end
    end
  end
end
