# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::TagList, :accession, type: :model do
  include Accession::Helpers

  let(:folder) { File.join('spec', 'data', 'accession') }
  let(:yaml) { load_file(folder, 'tags') }
  let(:tag_list) { described_class.new(yaml) }

  before do
    create(:insdc_country, :valid, name: 'Australia')
  end

  it 'has the correct number of tags' do
    expect(tag_list.count).to eq(yaml.count)
  end

  it 'is able to find a tag by its key' do
    expect(tag_list.find(yaml.keys.first.to_s).name).to eq(yaml.keys.first)
    expect(tag_list.find(yaml.keys.first.to_sym).name).to eq(yaml.keys.first)
    expect(tag_list.find(:dodgy_tag)).to be_nil
  end

  it 'picks out tags which are required for each service' do
    # Includes two optional tags sample_description and sample_strain_att
    expect(tag_list.required_for(build(:ena_service)).count).to eq(6)
    expect(tag_list.required_for(build(:ega_service)).count).to eq(7)
  end

  it 'groups the tags' do
    tags = tag_list.by_group # {name: TagList}
    expect(tags.count).to eq(3)
    expect(tags[:sample_name].count).to eq(2)
    # sample_attributes group includes two optional tags as well.
    expect(tags[:sample_attributes].count).to eq(7)
    # array_express group includes 17 tags
    expect(tags[:array_express].count).to eq(17)
  end

  it 'after grouping standard tag groups should not be nil' do
    extract = tag_list.extract(create(:minimal_sample_metadata_for_accessioning))
    groups = extract.by_group
    expect(groups.count).to eq(3)
    expect(groups[:sample_name].count).to eq(2)
    expect(groups[:sample_attributes].count).to eq(2)
    expect(groups[:array_express].count).to eq(1)
  end

  it '#extract should create a new tag list with tags that have values' do
    extract = tag_list.extract(create(:sample_metadata_for_accessioning))
    # minus 2 as have derived metadata sex and species
    # plus 1 as sample metadata includes sample_public_name which is not in standard tags
    expect(extract.count - 1).to eq(attributes_for(:sample_metadata_for_accessioning).count)
    expect(extract.find(:sample_common_name).value).to eq('A common name')
    expect(extract.find(:species).value).to eq('A common name')
    expect(extract.find(:gender).value).to eq('Unknown')
    expect(extract.find(:sex).value).to eq('unknown') # derived to lowercase
    expect(extract.find(:country_of_origin).value).to eq('Australia') # has to match with Insdc Country list
  end

  it '#extract should create a taglist that has groups' do
    extract = tag_list.extract(create(:minimal_sample_metadata_for_accessioning))
    expect(extract.groups).to include(:sample_name, :sample_attributes, :array_express)
  end

  it 'indicates whether service requirements are met' do
    extract = tag_list.extract(create(:sample_metadata_for_accessioning))
    expect(extract).to be_meets_service_requirements(build(:ena_service), tag_list)
    expect(extract).to be_meets_service_requirements(build(:ega_service), tag_list)

    extract = tag_list.extract(create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
    expect(extract).not_to be_meets_service_requirements(build(:ena_service), tag_list)
    expect(extract).not_to be_meets_service_requirements(build(:ega_service), tag_list)
    expect(extract.missing).to include('sample_taxon_id')
  end

  it 'is able to create a list of tags from a hash of tags' do
    tags = build_list(:accession_tag, 5).index_by(&:name)
    tag_list = described_class.new(tags)
    expect(tag_list.count).to eq(tags.count)
  end

  describe 'checking tag lists' do
    let(:sample_metadata) do
      Sample::Metadata.new(
        sample_taxon_id: 1, # mandatory
        sample_common_name: 'A common name', # mandatory
        country_of_origin: 'Australia', # mandatory
        date_of_sample_collection: '2000-01-01T00:00', # mandatory
        sample_description: 'A description' # optional
      )
    end
    let(:standard_tag_list) { described_class.new(yaml) }
    let(:sample_tag_list) { standard_tag_list.extract(sample_metadata) }

    context 'when all mandatory tags are present' do
      it 'returns true' do
        result = sample_tag_list.meets_service_requirements?(build(:ena_service), standard_tag_list)
        expect(result).to be true
      end
    end

    context 'when a mandatory tag is missing' do
      let(:sample_metadata) do
        Sample::Metadata.new(
          sample_taxon_id: 1, # mandatory
          # sample_common_name: 'A common name', # mandatory - missing and has no default value
          country_of_origin: 'Australia', # mandatory
          date_of_sample_collection: '2000-01-01T00:00', # mandatory
          sample_description: 'A description' # optional
        )
      end

      it 'returns false' do
        result = sample_tag_list.meets_service_requirements?(build(:ena_service), standard_tag_list)
        expect(result).to be false
      end
    end
  end
end
