# frozen_string_literal: true

require 'rails_helper'

COUNTRY_TAG = 'geographic location (country and/or sea)'
COLLECTION_DATE_TAG = 'collection date'

def find_value_at_tag(xml_received, tag_name)
  xml = Nokogiri::XML::Document.parse(xml_received)
  xml
    .at('SAMPLE_ATTRIBUTES')
    .children
    .each do |elem|
      return elem.search('VALUE').collect(&:text).first if elem.search('TAG').collect(&:text).first == tag_name
    end
end

RSpec.describe Accession::Sample, :accession, type: :model do
  let(:tag_list) { build(:standard_accession_tag_list) }

  before { @country = create(:insdc_country, name: 'Australia') }

  it 'is not sent for accessioning if the sample has already been accessioned' do
    sample =
      create(
        :sample_for_accessioning_with_open_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_ebi_accession_number: 'ENA123')
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  it "is not sent for accessioning if the sample doesn't have an appropriate study" do
    expect(described_class.new(tag_list, create(:sample))).not_to be_valid
    expect(described_class.new(tag_list, create(:sample, studies: [create(:open_study)]))).not_to be_valid

    sample =
      create(
        :sample,
        studies: [create(:open_study, accession_number: 'ENA123'), create(:managed_study, accession_number: 'ENA123')]
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid
  end

  it "is not sent for accessioning if the sample doesn't have the required fields" do
    sample =
      create(
        :sample_for_accessioning_with_open_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil)
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample =
      create(
        :sample_for_accessioning_with_open_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_common_name: nil)
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample =
      create(
        :sample_for_accessioning_with_managed_study,
        sample_metadata: create(:sample_metadata_for_accessioning, gender: nil)
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample =
      create(
        :sample_for_accessioning_with_managed_study,
        sample_metadata: create(:sample_metadata_for_accessioning, phenotype: nil)
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample =
      create(
        :sample_for_accessioning_with_managed_study,
        sample_metadata: create(:sample_metadata_for_accessioning, donor_id: nil)
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample =
      create(
        :sample_for_accessioning_with_managed_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_taxon_id: nil)
      )
    expect(described_class.new(tag_list, sample)).not_to be_valid

    sample =
      create(
        :sample_for_accessioning_with_managed_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_common_name: nil)
      )
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
    sample =
      create(
        :sample_for_accessioning_with_open_study,
        sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: 'Sample 666')
      )
    accession_sample = described_class.new(tag_list, sample)
    expect(accession_sample.name).to eq('sample_666')
    expect(accession_sample.title).to eq('Sample 666')

    sample =
      create(
        :sample_for_accessioning_with_open_study,
        name: 'Sample_1-',
        sample_metadata: create(:sample_metadata_for_accessioning, sample_public_name: nil)
      )
    accession_sample = described_class.new(tag_list, sample)
    expect(accession_sample.name).to eq('sample_1_')
    expect(accession_sample.title).to eq(sample.sanger_sample_id)
  end

  it 'creates some xml with valid attributes' do
    sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
    xml = sample.to_xml

    expect(xml).to match(/<SAMPLE_SET.*<SAMPLE.*<\/SAMPLE>.*<\/SAMPLE_SET>/m)
    expect(xml).to include(/<SAMPLE_SET.*<SAMPLE_ATTRIBUTES>.*<\/SAMPLE_ATTRIBUTES>.*<\/SAMPLE_SET>/m)

    expect(xml).to include("alias=\"#{sample.ebi_alias}\"")
    expect(xml).to include("<TITLE>#{sample.title}</TITLE>")

    tags = sample.tags.by_group[:sample_name]
    sample_name_tags = xml
    tags.each do |_label, tag|
      expect(sample_name_tags).to include("<#{tag.label}>#{tag.value}</#{tag.label}>")
    end
    sample_attributes_tags = xml

    tags = sample.tags.by_group[:sample_attributes]
    expect(sample_attributes_tags).to include(*tags.labels.map { |label| "<TAG>#{label}</TAG>" })
    expect(sample_attributes_tags).to include(*tags.values.map { |value| "<VALUE>#{value}</VALUE>" })

    tags = sample.tags.by_group[:array_express]
    expect(sample_attributes_tags).to include(*tags.array_express_labels.map { |label| "<TAG>#{label}</TAG>" })
    expect(sample_attributes_tags).to include(*tags.values.map { |value| "<VALUE>#{value}</VALUE>" })

    sample = described_class.new(tag_list, create(:sample_for_accessioning_with_managed_study))
    xml = sample.to_xml
    sample_attributes_tags = xml
    expect(sample_attributes_tags).not_to include(*tags.array_express_labels.map { |label| "<TAG>#{label}</TAG>" })
  end

  it 'can update accession number for sample' do
    sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
    expect(sample.update_accession_number('ENA1234')).to be_truthy
    expect(sample.ebi_accession_number).to eq('ENA1234')
  end

  describe '#to_xml' do
    context 'with country of origin' do
      it 'includes country of origin' do
        sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
        expect(sample.to_xml).to include(COUNTRY_TAG)
        expect(find_value_at_tag(sample.to_xml, COUNTRY_TAG)).to eq('Australia')
      end

      it 'displays not provided when country is empty' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(country_of_origin: nil)
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COUNTRY_TAG)
        expect(find_value_at_tag(sample.to_xml, COUNTRY_TAG)).to eq('not provided')
      end

      it 'displays not provided when country value is not provided' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(country_of_origin: 'not provided')
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COUNTRY_TAG)
        expect(find_value_at_tag(sample.to_xml, COUNTRY_TAG)).to eq('not provided')
      end

      it 'displays not provided when country value is wrong' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(country_of_origin: 'Freedonia')
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COUNTRY_TAG)
        expect(find_value_at_tag(sample.to_xml, COUNTRY_TAG)).to eq('not provided')
      end

      it 'displays missing when country of origin is specified as missing' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(country_of_origin: 'missing: human-identifiable')
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COUNTRY_TAG)
        expect(find_value_at_tag(sample.to_xml, COUNTRY_TAG)).to eq('missing: human-identifiable')
      end
    end

    context 'with collection date' do
      it 'includes collection date' do
        sample = described_class.new(tag_list, create(:sample_for_accessioning_with_open_study))
        expect(sample.to_xml).to include(COLLECTION_DATE_TAG)
        expect(find_value_at_tag(sample.to_xml, COLLECTION_DATE_TAG)).to eq('2000-01-01T00:00')
      end

      it 'displays not provided when collection date is empty' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(date_of_sample_collection: nil)
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COLLECTION_DATE_TAG)
        expect(find_value_at_tag(sample.to_xml, COLLECTION_DATE_TAG)).to eq('not provided')
      end

      it 'displays not provided when collection date is not provided' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(date_of_sample_collection: 'not provided')
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COLLECTION_DATE_TAG)
        expect(find_value_at_tag(sample.to_xml, COLLECTION_DATE_TAG)).to eq('not provided')
      end

      it 'displays not provided when collection date is wrong' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(date_of_sample_collection: '2000-99-01T00:00')
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COLLECTION_DATE_TAG)
        expect(find_value_at_tag(sample.to_xml, COLLECTION_DATE_TAG)).to eq('not provided')
      end

      it 'displays missing when collection date is specified as missing' do
        smpl = create(:sample_for_accessioning_with_open_study)
        smpl.sample_metadata.update(date_of_sample_collection: 'missing: human-identifiable')
        sample = described_class.new(tag_list, smpl)
        expect(sample.to_xml).to include(COLLECTION_DATE_TAG)
        expect(find_value_at_tag(sample.to_xml, COLLECTION_DATE_TAG)).to eq('missing: human-identifiable')
      end
    end
  end
end
