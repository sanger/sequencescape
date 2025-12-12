# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::ENATaxaClient do
  let(:client) { described_class.new }
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:test_conn) do
    Faraday.new do |f|
      f.response :json
      f.adapter :test, stubs
    end
  end

  describe '#conn' do
    it 'returns a Faraday connection with the correct URL' do
      expect(client.conn.url_prefix.to_s).to eq(configatron.ena_taxon_lookup_url)
    end

    it 'includes default headers' do
      expect(client.conn.headers['User-Agent']).to eq('Sequencescape ENA Taxa Client')
    end

    it 'uses a proxy if configured' do
      #  makes a call to BaseClient#proxy to check if a proxy is set
      allow(client).to receive(:proxy).and_return('http://proxy.example.com')
      client.conn # trigger the method
      expect(client).to have_received(:proxy)
    end
  end

  describe '#taxon_from_text' do
    before do
      stubs.get("any-name/#{suggestion}") { [200, {}, response_body] }
      allow(client).to receive(:conn).and_return(test_conn)
    end

    context 'when species-level results are found' do
      let(:suggestion) { 'human' }
      let(:response_body) do
        [{
          'taxId' => '9606',
          'scientificName' => 'Homo sapiens',
          'commonName' => 'human',
          'formalName' => 'true',
          'rank' => 'species',
          'division' => 'HUM',
          'lineage' => 'Eukaryota; Metazoa; Chordata; ...; Catarrhini; Hominidae; Homo; ',
          'geneticCode' => '1',
          'mitochondrialGeneticCode' => '2',
          'submittable' => 'true',
          'binomial' => 'true',
          'otherNames' => ['Homo sapiens Linnaeus, 1758:authority', 'human:genbank common name'],
          'metagenome' => 'false'
        }]
      end

      it 'returns the relevant details from the first taxon' do
        expect(client.taxon_from_text(suggestion)).to eq(
          {
            'commonName' => 'human',
            'scientificName' => 'Homo sapiens',
            'taxId' => '9606',
            'submittable' => 'true'
          }
        )
      end
    end

    context 'when species-level results are not found' do
      let(:suggestion) { 'hominidae' }
      let(:response_body) do
        [{
          'taxId' => '9604',
          'scientificName' => 'Hominidae',
          'formalName' => 'false',
          'rank' => 'family',
          'division' => 'MAM',
          'lineage' => 'Eukaryota; Metazoa; ...; Primates; Haplorrhini; Catarrhini; ',
          'geneticCode' => '1',
          'mitochondrialGeneticCode' => '2',
          'submittable' => 'false',
          'binomial' => 'false',
          'authority' => 'Gray, 1825',
          'otherNames' => ['Hominidae Gray, 1825:authority', 'Pongidae:synonym', 'great apes:genbank common name'],
          'metagenome' => 'false'
        }]
      end

      it 'returns the relevant details from the first taxon' do
        expect(client.taxon_from_text(suggestion)).to eq(
          {
            'commonName' => nil,
            'scientificName' => 'Hominidae',
            'taxId' => '9604',
            'submittable' => 'false'
          }
        )
      end
    end

    context 'when no results are found' do
      let(:suggestion) { 'Supercalifragilisticexpialidocious' }
      let(:response_body) { [] }

      it 'returns nil' do
        expect(client.taxon_from_text(suggestion)).to be_nil
      end
    end
  end

  describe '#taxon_from_id' do
    let(:taxon_id) { '9606' }

    before do
      stubs.get("tax-id/#{taxon_id}") { [200, {}, response_body] }
      allow(client).to receive(:conn).and_return(test_conn)
    end

    context 'with a full response' do
      let(:response_body) do
        {
          'taxId' => '9606',
          'scientificName' => 'Homo sapiens',
          'commonName' => 'human',
          'formalName' => 'true',
          'rank' => 'species',
          'division' => 'HUM',
          'lineage' => 'Eukaryota; Metazoa; Chordata; Craniata; ... Hominidae; Homo; ',
          'geneticCode' => '1',
          'mitochondrialGeneticCode' => '2',
          'submittable' => 'true',
          'binomial' => 'true',
          'authority' => 'Linnaeus, 1758',
          'otherNames' => ['Homo sapiens Linnaeus, 1758:authority', 'human:genbank common name'],
          'metagenome' => 'false'
        }
      end

      it 'returns taxId, scientificName, and commonName' do
        expect(client.taxon_from_id(taxon_id)).to eq(
          { 'commonName' => 'human', 'scientificName' => 'Homo sapiens', 'taxId' => '9606' }
        )
      end
    end

    context 'with a partial response' do
      let(:response_body) do
        {
          'taxId' => '9606',
          'scientificName' => 'Homo sapiens',
          'comment' => 'commonName is missing'
        }
      end

      it 'returns nils if common name is missing' do
        expect(client.taxon_from_id(taxon_id)).to eq(
          { 'commonName' => nil, 'scientificName' => 'Homo sapiens', 'taxId' => '9606' }
        )
      end
    end

    context 'with no responses' do
      let(:response_body) { {} }

      it 'returns nils if no responses are returned' do
        expect(client.taxon_from_id(taxon_id)).to eq(
          { 'commonName' => nil, 'scientificName' => nil, 'taxId' => nil }
        )
      end
    end
  end
end
