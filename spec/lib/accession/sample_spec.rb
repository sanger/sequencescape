# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Sample, type: :model, accession: true do
  let(:tag_list) { build(:standard_accession_tag_list) }

  it 'is not sent for accessioning if the sample has already been accessioned' do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_ebi_accession_number: 'ENA123'))
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  it "is not sent for accessioning if the sample doesn't have an appropriate study" do
    expect(described_class.new(tag_list, create(:sample))).not_to be_valid
    expect(described_class.new(tag_list, create(:sample, studies: [create(:open_study)]))).not_to be_valid

    sample = create(:sample, studies: [create(:open_study, accession_number: 'ENA123'), create(:managed_study, accession_number: 'ENA123')])
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  it "is not sent for accessioning if the sample doesn't have the required fields" do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, gender: nil))
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, phenotype: nil))
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, donor_id: nil))
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample = create(:sample_for_accessioning_with_managed_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  it 'an appropriate service should be chosen based on the associated study' do
    sample = create(:sample_for_accessioning_with_open_study)
    expect(described_class.new(tag_list, sample).service).to be_ena

    sample = create(:sample_for_accessioning_with_managed_study)
    expect(described_class.new(tag_list, sample).service).to be_ega

    sample = create(:sample, studies: [create(:open_study)])
    expect(described_class.new(tag_list, sample).service).not_to be_valid
  end

  it 'has a name and a title' do
    sample = create(:sample_for_accessioning_with_open_study, sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: 'Sample 666'))
    accession_sample = described_class.new(tag_list, sample)
    expect(accession_sample.name).to eq('sample_666')
    expect(accession_sample.title).to eq('Sample 666')

    sample = create(:sample_for_accessioning_with_open_study, name: 'Sample_1-', sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: nil))
    accession_sample = described_class.new(tag_list, sample)
    expect(accession_sample.name).to eq('sample_1_')
    expect(accession_sample.title).to eq(sample.sanger_sample_id)
  end

  it 'creates some xml with valid attributes' do
    sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
    xml = Nokogiri::XML::Document.parse(sample.to_xml)

    expect(xml.at('SAMPLE_SET').at('SAMPLE').at('SAMPLE_ATTRIBUTES')).not_to be_nil

    expect(xml.at('SAMPLE').attribute('alias').value).to eq(sample.ebi_alias)
    expect(xml.at('TITLE').text).to eq(sample.title)

    tags = sample.tags.by_group[:sample_name]
    sample_name_tags = xml.at('SAMPLE_NAME')
    tags.each do |_label, tag|
      expect(sample_name_tags.search(tag.label).children.first.text).to eq(tag.value)
    end

    sample_attributes_tags = xml.at('SAMPLE_ATTRIBUTES')

    tags = sample.tags.by_group[:sample_attributes]
    expect(sample_attributes_tags.search('TAG').collect(&:text) & tags.labels).to eq(tags.labels)
    expect(sample_attributes_tags.search('VALUE').collect(&:text) & tags.values).to eq(tags.values)

    tags = sample.tags.by_group[:array_express]
    expect(sample_attributes_tags.search('TAG').collect(&:text) & tags.array_express_labels).to eq(tags.array_express_labels)
    expect(sample_attributes_tags.search('VALUE').collect(&:text) & tags.values).to eq(tags.values)

    sample = described_class.new(tag_list, create(:sample_for_accessioning_with_managed_study))
    xml = Nokogiri::XML::Document.parse(sample.to_xml)
    sample_attributes_tags = xml.at('SAMPLE_ATTRIBUTES')
    expect(sample_attributes_tags.search('TAG').collect(&:text) & tags.array_express_labels).to be_empty
  end

  it 'can update accession number for sample' do
    sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
    expect(sample.update_accession_number('ENA1234')).to be_truthy
    expect(sample.ebi_accession_number).to eq('ENA1234')
  end
end
