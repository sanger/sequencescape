# frozen_string_literal: true

require 'rails_helper'
require 'ebi_check/client'

# rubocop:disable RSpec/MultipleExpectations
RSpec.describe EBICheck::Client do
  let(:drop_box_url) { 'https://example.com/ena/submit/drop-box' }
  let(:ega_options) { { user: 'ega_user', password: 'ega_pw' } }
  let(:ena_options) { { user: 'ena_user', password: 'ena_pw' } }

  around do |example|
    original_drop_box_url = configatron.accession.drop_box_url!
    original_ena = configatron.accession.ena!
    original_ega = configatron.accession.ega!

    configatron.accession.drop_box_url = drop_box_url
    configatron.accession.ena = ena_options
    configatron.accession.ega = ega_options

    example.run

    configatron.accession.drop_box_url = original_drop_box_url
    configatron.accession.ena = original_ena
    configatron.accession.ega = original_ega
  end

  describe '.for_ega_samples' do
    it 'creates a client with correct url and options' do
      client = described_class.for_ega_samples
      expect(client.send(:url)).to eq("#{drop_box_url}/samples/")
      expect(client.send(:options)).to eq(ega_options)
    end
  end

  describe '.for_ega_studies' do
    it 'creates a client with correct url and options' do
      client = described_class.for_ega_studies
      expect(client.send(:url)).to eq("#{drop_box_url}/studies/")
      expect(client.send(:options)).to eq(ega_options)
    end
  end

  describe '.for_ena_samples' do
    it 'creates a client with correct url and options' do
      client = described_class.for_ena_samples
      expect(client.send(:url)).to eq("#{drop_box_url}/samples/")
      expect(client.send(:options)).to eq(ena_options)
    end
  end

  describe '.for_ena_studies' do
    it 'creates a client with correct url and options' do
      client = described_class.for_ena_studies
      expect(client.send(:url)).to eq("#{drop_box_url}/studies/")
      expect(client.send(:options)).to eq(ena_options)
    end
  end

  describe '#initialize' do
    it 'sets the url' do
      url = 'https://example.com/api/'
      client = described_class.new(url, {})
      expect(client.send(:url)).to eq(url)
    end

    it 'sets the options' do
      options = { user: 'test_user', password: 'test_pw' }
      client = described_class.new('https://example.com/api/', options)
      expect(client.send(:options)).to eq(options)
    end

    it 'appends a trailing slash to url if missing' do
      client = described_class.new('https://example.com/api', {})
      expect(client.send(:url)).to eq('https://example.com/api/')
    end
  end

  describe '#inspect' do
    it 'redacts the password in options' do
      client = described_class.for_ena_samples
      expect(client.inspect).to include('[FILTERED]')
      expect(client.inspect).not_to include('secret')
    end
  end

  describe '#get' do
    let(:accession_number) { 'ERS12345678' }
    let(:xml_response) { '<SAMPLE_SET><SAMPLE accession="ERS12345678"></SAMPLE></SAMPLE_SET>' }
    let(:request_url) { "#{drop_box_url}/samples/#{accession_number}" }

    before do
      stub_request(:get, "#{drop_box_url}/samples/#{accession_number}").to_return(status: 200, body: xml_response)
    end

    it 'returns XML when called with an accession number' do
      client = described_class.for_ena_samples
      response = client.get(accession_number)
      expect(WebMock).to have_requested(:get, request_url)
      expect(response.body).to eq(xml_response)
      expect(response.body).to include('<SAMPLE_SET>')
    end
  end
end
# rubocop:enable RSpec/MultipleExpectations
