# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::AccessioningV1Client do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_conn) do
    Faraday.new do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new }
  let(:login) { { user: 'user', password: 'pass' } }

  let(:sample_file) do
    instance_double(File, path: 'path/to/123_sample_file.xml', read: '<xml>sample</xml>', rewind: true, close: true)
  end
  let(:submission_file) do
    instance_double(File, path: 'path/to/456_submission_file.xml', read: '<xml>submission</xml>', rewind: true,
                          close: true)
  end
  let(:files) { { 'SAMPLE' => sample_file, 'SUBMISSION' => submission_file } }

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

  after do
    Faraday.default_connection = nil # remove any stubs after each test
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
    before do
      allow(client).to receive(:conn).and_return(test_conn)
    end

    context 'when the response is successful' do
      before do
        stubs.post('') { [200, {}, success_response] }
      end

      it 'returns the accession number' do
        expect(client.submit_and_fetch_accession_number(login, files)).to eq('EGA00001000240')
      end
    end

    context 'when the response is a failure' do
      before do
        stubs.post('') { [200, {}, failure_response] }
      end

      it 'raises Accession::Error with error messages' do
        expect do
          client.submit_and_fetch_accession_number(login, files)
        end.to raise_error(Accession::Error, "#{error_message1}; #{error_message2}")
      end
    end

    context 'when the server returns a 400 error with error messages' do
      before do
        stubs.post('') { [400, {}, failure_response] }
      end

      it 'raises Accession::Error with error messages' do
        expect do
          client.submit_and_fetch_accession_number(login, files)
        end.to raise_error(Accession::Error, "#{error_message1}; #{error_message2}")
      end
    end

    context 'when the server returns a 400 error with no body' do
      before do
        stubs.post('') { [400, {}, 'Bad Request'] }
      end

      it 'raises a Accession::Error' do
        expect { client.submit_and_fetch_accession_number(login, files) }
          .to raise_error(Accession::Error, 'Posting of accession submission failed')
      end
    end

    context 'when the server returns a 500 error' do
      before do
        stubs.post('') { [500, {}, 'Internal Server Error'] }
      end

      it 'raises an Accession::Error' do
        expect { client.submit_and_fetch_accession_number(login, files) }
          .to raise_error(Accession::Error, 'Posting of accession submission failed')
      end
    end

    context 'when the server is unreachable' do
      before do
        stubs.post('') { raise Faraday::ConnectionFailed, 'Connection failed' }
      end

      it 'raises a Faraday::Error error' do
        expect do
          client.submit_and_fetch_accession_number(login, files)
        end.to raise_error(Faraday::Error, 'Connection failed')
      end
    end
  end

  # rubocop:disable RSpec/ExampleLength, RSpec/MultipleExpectations
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
    end

    around do |example|
      configatron_dup = configatron.dup
      configatron.accession.url = 'http://example.com/submit/'

      example.run

      configatron_dup
    end

    let(:client) { described_class.new }

    it 'sends the correct multipart/form-data payload' do
      Dir.mktmpdir do |tmpdir|
        sample_file = File.join(tmpdir, 'sample.xml')
        File.write(sample_file, '<xml>sample</xml>')

        submission_file = File.join(tmpdir, 'submission.xml')
        File.write(submission_file, '<xml>submission</xml>')

        files = {
          'SAMPLE' => File.open(sample_file, 'r'),
          'SUBMISSION' => File.open(submission_file, 'r')
        }

        response = client.submit_and_fetch_accession_number(login, files)

        expect(response).to eq('EGA00001000240')

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
  # rubocop:enable RSpec/ExampleLength, RSpec/MultipleExpectations
end
