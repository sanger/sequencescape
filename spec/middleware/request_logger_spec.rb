# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RequestLogger do
  let(:env) do
    Rack::MockRequest.env_for(
      '/samples/1234?foo=bar',
      'REQUEST_METHOD' => 'GET',
      'REMOTE_ADDR' => '172.12.345.10',
      'action_dispatch.request_id' => 'test-request-id',
      'action_dispatch.request.parameters' => {},
      'action_dispatch.request.formats' => [Mime[:html]]
    )
  end

  let(:status_code) { 200 }
  let(:app) { ->(_env) { [status_code, { 'Content-Type' => 'text/html' }, 'Response Body'] } }

  before do
    allow(Rack::Utils).to receive(:clock_time).and_return(1.0, 1.23) # Simulate elapsed time for request processing
    allow(Time.zone).to receive(:now).and_return(Time.new(2026, 2, 12, 12, 10, 50, '+00:00'))
    allow(Rails.logger).to receive(:debug)
    allow(Rails.logger).to receive(:info)
  end

  shared_examples 'logs request with' do |log_level|
    let(:middleware) do
      described_class.new(app, log_level: log_level,
                               environment_context: { host: 'www.example.com', version: '1.2.3' })
    end

    it 'calls the app and returns the response' do
      expect(middleware.call(env)).to eq([status_code, { 'Content-Type' => 'text/html' }, 'Response Body'])
    end

    context 'when logging a request' do
      before do
        middleware.call(env)
      end

      it 'records the request method' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"method":"GET"/))
      end

      it 'records the request path' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(%r{"path":"/samples/1234\?foo=bar"}))
      end

      it 'records the request format' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"format":"html"/))
      end

      it 'records the response status code' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"status_code":#{status_code}/))
      end

      it 'records the response status message' do
        status_message = Rack::Utils::HTTP_STATUS_CODES[status_code] || 'Unknown Status'

        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"status_message":"#{status_message}"/))
      end

      it 'records the request duration in milliseconds' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"duration_ms":230/))
      end

      it 'records the client IP address' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"client_ip":"172\.12\.345\.10"/))
      end

      it 'records the request ID' do
        expect(Rails.logger).to have_received(log_level).with(a_string_matching(/"request_id":"test-request-id"/))
      end

      it 'records the environment context' do
        expect(Rails.logger).to have_received(log_level)
          .with(a_string_matching(/"host":"www\.example\.com","version":"1\.2\.3"/))
      end

      it 'includes the request tags' do # rubocop:disable RSpec/ExampleLength
        request_tags = ['request']
        request_tags << case status_code
                        when 100..199 then 'informational'
                        when 200..299 then 'success'
                        when 300..399 then 'redirection'
                        when 400..499 then 'client_error'
                        when 500..599 then 'server_error'
        end
        request_tags.compact!

        expect(Rails.logger).to have_received(log_level)
          .with(a_string_matching(/"tags":\["#{request_tags.join('","')}"\]/))
      end

      it 'records the timestamp' do
        expect(Rails.logger).to have_received(log_level)
          .with(a_string_matching(/"@timestamp":"2026-02-12T12:10:50\.000\+00:00"/))
      end
    end
  end

  context 'when response is 200 OK' do
    let(:status_code) { 200 }

    it_behaves_like 'logs request with', :info
  end

  context 'when response is 404 Not Found' do
    let(:status_code) { 404 }

    it_behaves_like 'logs request with', :info
  end

  context 'when response is 500 Internal Server Error' do
    let(:status_code) { 500 }

    it_behaves_like 'logs request with', :info
  end

  context 'when response is 789 Unknown Status' do
    let(:status_code) { 789 }

    it_behaves_like 'logs request with',  :info
  end

  context 'when log level is set to :debug' do
    it_behaves_like 'logs request with',  :debug
  end
end
