# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::AccessioningV1Client do
  let(:client) { described_class.new }
  let(:login) { { user: 'user', password: 'pass' } }
  let(:files) { {} }

  let(:success_response) do
    <<-XML
      <RECEIPT receiptDate="2014-12-02T16:06:20.871Z" success="true">
        <SAMPLE accession="EGA00001000240"/>
        <SUBMISSION accession="ERA390457" alias="submission_1"/>
        <ACTIONS>ADD</ACTIONS>
      </RECEIPT>
    XML
  end
  let(:error_message1) { "Houston, we've had a problem." }
  let(:error_message2) { "We've had a Main B Bus Undervolt." }
  let(:failure_response) do
    <<-XML
      <RECEIPT receiptDate="2014-12-02T16:06:20.871Z" success="false">
        <MESSAGES>
          <ERROR>#{error_message1}</ERROR>
          <ERROR>#{error_message2}</ERROR>
        </RECEIPT>
      </RECEIPT>
    XML
  end

  describe '#conn' do
    it 'returns a Faraday connection with the correct URL' do
      expect(client.conn.url_prefix.to_s).to eq(configatron.accession.url)
    end

    it 'sets the correct headers' do
      expect(client.conn.headers).to include(
        'User-Agent' => 'Sequencescape Accessioning V1 Client'
      )
    end

    it 'uses a proxy if configured' do
      #  makes a call to BaseClient#proxy to check if a proxy is set
      allow(client).to receive(:proxy).and_return('http://proxy.example.com')
      client.conn # trigger the method
      expect(client).to have_received(:proxy)
    end
  end

  describe '#submit_and_fetch_accession_number' do
    context 'when the response is successful' do
      before do
        stub_request(:post, configatron.accession.url).to_return(status: 200, body: success_response)
      end

      it 'returns the accession number' do
        expect(client.submit_and_fetch_accession_number(login, files)).to eq('EGA00001000240')
      end
    end

    context 'when the response is a failure' do
      before do
        stub_request(:post, configatron.accession.url).to_return(status: 200, body: failure_response)
      end

      it 'raises Accession::ExternalValidationError with error messages' do
        expect do
          client.submit_and_fetch_accession_number(login, files)
        end.to raise_error(Accession::ExternalValidationError, "#{error_message1}; #{error_message2}")
      end
    end

    context 'when the server returns a 400 error with error messages' do
      before do
        stub_request(:post, configatron.accession.url).to_return(status: 400, body: failure_response)
      end

      it 'raises Accession::ExternalValidationError with error messages' do
        expect do
          client.submit_and_fetch_accession_number(login, files)
        end.to raise_error(Accession::ExternalValidationError, "#{error_message1}; #{error_message2}")
      end
    end

    context 'when the server returns a 400 error with no body' do
      before do
        stub_request(:post, configatron.accession.url).to_return(status: 400, body: 'Bad Request')
      end

      it 'raises a Accession::ExternalValidationError' do
        expect { client.submit_and_fetch_accession_number(login, files) }
          .to raise_error(Accession::ExternalValidationError,
                          'Failed to process accessioning response, the response status code was 400.')
      end
    end

    context 'when the server returns a 500 error' do
      before do
        stub_request(:post, configatron.accession.url).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'raises an Accession::ExternalValidationError' do
        expect { client.submit_and_fetch_accession_number(login, files) }
          .to raise_error(Accession::ExternalValidationError,
                          'Failed to process accessioning response, the response status code was 500.')
      end
    end

    context 'when the server is unreachable' do
      before do
        stub_request(:post, configatron.accession.url).to_raise(Faraday::ConnectionFailed.new('Connection failed'))
      end

      it 'raises a Faraday::Error error' do
        expect do
          client.submit_and_fetch_accession_number(login, files)
        end.to raise_error(Faraday::Error, 'Connection failed')
      end
    end
  end

  context 'when inspecting the outgoing request' do
    # While not a perfect test, this checks that the client and resultant request are largely correct.
    # This makes a good reference for what the version 1 ENA API expects. Should the implementation
    # change (again), this would be a good place to start.
    # See the links below for more information:
    # API v1 Usage Guide: https://ena-docs.readthedocs.io/en/latest/submit/general-guide/webin-v1.html
    # API v1 Documentation: https://wwwdev.ebi.ac.uk/ena/submit/drop-box/swagger-ui/index.html#/submit/submitXml
    # Multipart Form Data: https://www.w3.org/Protocols/rfc1341/7_2_Multipart.html

    before do
      stub_request(:post, 'http://example.com/submit/').to_return(status: 200, body: success_response)

      Dir.mktmpdir do |tmpdir|
        sample_file = File.join(tmpdir, 'sample.xml')
        File.write(sample_file, '<xml>sample</xml>')

        submission_file = File.join(tmpdir, 'submission.xml')
        File.write(submission_file, '<xml>submission</xml>')

        files = {
          'SAMPLE' => File.open(sample_file, 'r'),
          'SUBMISSION' => File.open(submission_file, 'r')
        }

        client.submit_and_fetch_accession_number(login, files)
      end
    end

    around do |example|
      configatron_dup = configatron.dup
      configatron.accession.url = 'http://example.com/submit/'

      example.run

      configatron_dup
    end

    let(:client) { described_class.new }

    it 'sends the correct multipart/form-data payload' do # rubocop:disable RSpec/ExampleLength,RSpec/MultipleExpectations
      # Inspect the last request
      request = WebMock::RequestRegistry.instance.requested_signatures.hash.keys.last

      expect(request.headers['User-Agent']).to eq('Sequencescape Accessioning V1 Client')
      expect(request.headers['Authorization']).to eq("Basic #{Base64.strict_encode64('user:pass')}")
      expect(request.headers['Content-Type']).to match(%r{^multipart/form-data; boundary=})

      expect(request.body).to include('Content-Disposition: form-data; name="SAMPLE"; filename="sample.xml"')
      expect(request.body).to include('Content-Disposition: form-data; name="SUBMISSION"; filename="submission.xml"')
      expect(request.body.scan('Content-Type: text/plain').size).to eq(2) # should appear once for each file

      expect(request.body).to include('<xml>sample</xml>')
      expect(request.body).to include('<xml>submission</xml>')
    end
  end
end
