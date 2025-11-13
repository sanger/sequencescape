# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::NCBITaxaClient do
  let(:conn) { Faraday.new { |f| f.adapter :test, stubs } }
  let(:client) { described_class.new(conn) }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }

  describe '#id_from_text' do
    let(:suggestion) { 'homo sapiens' }
    let(:response_body) { '9606' }

    before do
      stubs.get('/esearch.fcgi') { [200, { 'Content-Type' => 'text/xml' }, response_body] }
    end

    it 'returns the response body for a valid suggestion' do
      expect(client.id_from_text(suggestion)).to eq(response_body)
    end
  end

  describe '#name_from_id' do
    let(:taxon_id) { '9606' }
    let(:response_body) { 'Homo sapiens' }

    before do
      stubs.get('/efetch.fcgi') { [200, { 'Content-Type' => 'text/xml' }, response_body] }
    end

    it 'returns the response body for a valid taxon id' do
      expect(client.name_from_id(taxon_id)).to eq(response_body)
    end
  end
end
