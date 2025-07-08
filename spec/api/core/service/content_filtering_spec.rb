# frozen_string_literal: true

require 'rails_helper'
require 'sinatra/base'
require 'stringio'

RSpec.describe Core::Service::ContentFiltering::Helpers do
  let(:body_content) { '{"foo":"bar"}' }
  let(:body_io) { instance_double(StringIO, read: body_content, rewind: nil) }
  let(:content_type) { 'application/json' }
  let(:request) do
    instance_double(
      Sinatra::Request,
      body: body_io,
      content_type: content_type
    )
  end

  # Create a dummy class including the Helpers module
  let(:helpers_instance) do
    Class.new do
      include Core::Service::ContentFiltering::Helpers
      def request
      end
    end.new
  end

  before do
    allow(helpers_instance).to receive(:request).and_return(request)
  end

  describe '.process_request_body' do
    context 'when content type is acceptable and body is present' do
      it 'parses JSON and assigns to @json' do
        helpers_instance.process_request_body
        expect(helpers_instance.json).to eq({ 'foo' => 'bar' })
      end
    end

    context 'when content type is not acceptable and body is present' do
      let(:content_type) { 'text/plain' }

      it 'raises InvalidBodyContentType' do
        expect do
          helpers_instance.process_request_body
        end.to raise_error(Core::Service::ContentFiltering::InvalidBodyContentType)
      end
    end

    context 'when content type is application/json and body is blank' do
      let(:body_content) { '' }

      it 'sets @json to an empty hash' do
        helpers_instance.process_request_body
        expect(helpers_instance.json).to eq({})
      end
    end

    context 'when content is blank regardless of content type' do
      let(:body_content) { '' }
      let(:content_type) { 'custom/type' }

      it 'sets @json to an empty hash' do
        helpers_instance.process_request_body
        expect(helpers_instance.json).to eq({})
      end
    end

    it 'rewinds the request body after processing' do
      begin
        helpers_instance.process_request_body
      rescue Core::Service::ContentFiltering::InvalidBodyContentType
        # ignore for this test
      end
      expect(request.body).to have_received(:rewind)
    end
  end
end
