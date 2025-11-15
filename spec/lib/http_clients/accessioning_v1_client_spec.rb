# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::AccessioningV1Client do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) do
    Faraday.new do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(conn) }
  let(:login) { { username: 'user', password: 'pass' } }
  let(:payload_io) { StringIO.new('<SAMPLE_SET></SAMPLE_SET>') }

  let(:service) { instance_double(Accession::Service, login:) }
  let(:payload) { instance_double(Accession::Submission::Payload, open: payload_io, close!: true) }
  let(:submission) { instance_double(Accession::Submission, service:, payload:) }

  let(:success_response) do
    <<-XML
      <RECEIPT success="true">
        <SAMPLE accession="EGA00001000240" />
        <SUBMISSION accession="EGA00001000240" />
      </RECEIPT>
    XML
  end
  let(:error_message1) { 'Houston, we\'ve had a problem.' }
  let(:error_message2) { 'We\'ve had a Main B Bus Undervolt.' }
  let(:failure_response) do
    <<-XML
      <RECEIPT success="false">
        <ERROR>#{error_message1}</ERROR>
        <ERROR>#{error_message2}</ERROR>
      </RECEIPT>
    XML
  end

  describe '#submit_and_fetch_accession_number' do
    context 'when the response is successful' do
      before do
        stubs.post('/') { [200, {}, success_response] }
      end

      it 'returns the accession number' do
        expect(client.submit_and_fetch_accession_number(submission)).to eq('EGA00001000240')
      end
    end

    context 'when the response is a failure' do
      before do
        stubs.post('/') { [200, {}, failure_response] }
      end

      it 'raises Accession::Error with error messages' do
        expect do
          client.submit_and_fetch_accession_number(submission)
        end.to raise_error(Accession::Error, "#{error_message1}; #{error_message2}")
      end
    end

    context 'when the server returns a 400 error with error messages' do
      before do
        stubs.post('/') { [400, {}, failure_response] }
      end

      it 'raises Accession::Error with error messages' do
        expect do
          client.submit_and_fetch_accession_number(submission)
        end.to raise_error(Accession::Error, "#{error_message1}; #{error_message2}")
      end
    end

    context 'when the server returns a 400 error with no body' do
      before do
        stubs.post('/') { [400, {}, 'Bad Request'] }
      end

      it 'raises a Accession::Error' do
        expect { client.submit_and_fetch_accession_number(submission) }
          .to raise_error(Accession::Error, 'Posting of accession submission failed')
      end
    end

    context 'when the server returns a 500 error' do
      before do
        stubs.post('/') { [500, {}, 'Internal Server Error'] }
      end

      it 'raises an Accession::Error' do
        expect { client.submit_and_fetch_accession_number(submission) }
          .to raise_error(Accession::Error, 'Posting of accession submission failed')
      end
    end

    context 'when the server is unreachable' do
      before do
        stubs.post('/') { raise Faraday::ConnectionFailed, 'Connection failed' }
      end

      it 'raises a Faraday::Error error' do
        expect do
          client.submit_and_fetch_accession_number(submission)
        end.to raise_error(Faraday::Error, 'Connection failed')
      end
    end
  end
end
