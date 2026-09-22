# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Sample XML interface' do
  let(:sample) { create(:sample) }

  it 'returns the sample and its metadata as XML' do
    visit sample_path(sample, format: :xml)

    response = Hash.from_xml(page.body).fetch('sample')
    properties = response.fetch('properties').fetch('property').to_h do |property|
      [property.fetch('name'), property['value'].to_s]
    end

    expect(response).to include(
      'api_version' => '0.6',
      'name' => sample.name,
      'consent_withdrawn' => 'false'
    )
    expect(properties).to eq(
      'Consent withdrawn' => 'false',
      'Date of consent withdrawn' => '',
      'Identifier of the user that withdrew consent' => '',
      'Cohort' => '',
      'Common Name' => '',
      'Concentration' => '',
      'Concentration determind by' => '',
      'Country of origin' => '',
      'DNA source' => '',
      'Date of sample collection' => '',
      'Date of sample extraction' => '',
      'ENA Sample Accession Number' => '',
      'Ethnicity' => '',
      'Father' => '',
      'GC content' => '',
      'Gender' => '',
      'Geographical region' => '',
      'Is re-submitted?' => '',
      'Mother' => '',
      'Organism' => '',
      'Volume (µl)' => '',
      'Taxon ID' => '',
      'Public Name' => '',
      'Purification method' => '',
      'Reference Genome' => '',
      'Replicate' => '',
      'Sample Description' => '',
      'Sample Visibility' => '',
      'Sample extraction method' => '',
      'Sample purified' => '',
      'Sample storage conditions' => '',
      'Sample type' => '',
      'Sibling' => '',
      'Strain' => '',
      'Genome Size' => '',
      'Genotype' => '',
      'Phenotype' => '',
      'Age' => '',
      'Developmental Stage' => '',
      'Cell Type' => '',
      'Subject' => '',
      'Disease' => '',
      'Disease State' => '',
      'Treatment' => '',
      'Compound' => '',
      'Dose' => '',
      'Immunoprecipitate' => '',
      'Growth Condition' => '',
      'RNAi' => '',
      'Organism Part' => '',
      'Time Point' => '',
      'Donor Id' => '',
      'Collected By' => ''
    )
  end
end
