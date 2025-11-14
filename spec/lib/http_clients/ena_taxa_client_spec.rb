# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HTTPClients::ENATaxaClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:conn) do
    Faraday.new do |f|
      f.response :json
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(conn) }

  describe '#taxon_from_text' do
    before do
      stubs.get("suggest-for-submission/#{suggestion}") { [200, {}, response_body] }
    end

    context 'when results are found' do
      let(:suggestion) { 'human' }
      let(:response_body) do
        [{
          'taxId' => '9606',
          'scientificName' => 'Homo sapiens',
          'commonName' => 'human',
          'binomial' => 'true',
          'otherNames' => ['Homo sapiens Linnaeus, 1758:authority', 'human:genbank common name'],
          'metagenome' => 'false'
        }, {
          'taxId' => '646099',
          'scientificName' => 'human metagenome',
          'binomial' => 'true',
          'otherNames' => ['human microbiota:includes', 'human metabiome:synonym', 'human microbiome:synonym'],
          'metagenome' => 'true'
        }, {
          'taxId' => '557562',
          'scientificName' => 'Human bocavirus human/2/2008/HUN',
          'binomial' => 'true',
          'otherNames' => ['Human bocavirus HuBoV/human/2/2008/HUN:equivalent name'],
          'metagenome' => 'false'
        }]
      end

      it 'returns the taxId, scientificName, and commonName of the first taxon' do
        expect(client.taxon_from_text(suggestion)).to eq(
          { 'commonName' => 'human', 'scientificName' => 'Homo sapiens', 'taxId' => '9606' }
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
