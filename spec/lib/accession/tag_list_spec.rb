require 'rails_helper'

RSpec.describe Accession::TagList, type: :model, accession: true do
  include Accession::Helpers

  let(:folder)      { File.join('spec', 'data', 'accession') }
  let(:yaml)        { load_file(folder, 'tags') }
  let(:tag_list)    { Accession::TagList.new(yaml) }

  it 'should have the correct number of tags' do
    expect(tag_list.count).to eq(yaml.count)
  end

  it 'should be able to find a tag by its key' do
    expect(tag_list.find(yaml.keys.first.to_s).name).to eq(yaml.keys.first)
    expect(tag_list.find(yaml.keys.first.to_sym).name).to eq(yaml.keys.first)
    expect(tag_list.find(:dodgy_tag)).to be_nil
  end

  it 'should pick out tags which are required for each service' do
    expect(tag_list.required_for(build(:ena_service)).count).to eq(2)
    expect(tag_list.required_for(build(:ega_service)).count).to eq(5)
  end

  it 'should group the tags' do
    tags = tag_list.by_group
    expect(tags.count).to eq(3)
    expect(tags[:sample_name].count).to eq(2)
    expect(tags[:sample_attributes].count).to eq(3)
    expect(tags[:array_express].count).to eq(6)
  end

  it 'after grouping standard tag groups should not be nil' do
    extract = tag_list.extract(create(:minimal_sample_metadata_for_accessioning))
    groups = extract.by_group
    expect(groups.count).to eq(3)
    expect(groups[:sample_name].count).to eq(2)
    expect(groups[:sample_attributes].count).to eq(0)
    expect(groups[:array_express].count).to eq(1)
  end

  it '#extract should create a new tag list with tags that have values' do
    metadata = create(:sample_metadata_for_accessioning)
    extract = tag_list.extract(create(:sample_metadata_for_accessioning))
    expect(extract.count).to eq(attributes_for(:sample_metadata_for_accessioning).count)
    expect(extract.find(:sample_common_name).value).to eq('A common name')
  end

  it '#extract should create a taglist that has groups ' do
    extract = tag_list.extract(create(:minimal_sample_metadata_for_accessioning))
    expect(extract.groups).to include(:sample_name, :sample_attributes, :array_express)
  end

  it 'should indicate whether service requirements are met' do
    extract = tag_list.extract(create(:sample_metadata_for_accessioning))
    expect(extract.meets_service_requirements?(build(:ena_service), tag_list)).to be_truthy
    expect(extract.meets_service_requirements?(build(:ega_service), tag_list)).to be_truthy

    extract = tag_list.extract(create(:sample_metadata_for_accessioning, sample_taxon_id: nil))
    expect(extract.meets_service_requirements?(build(:ena_service), tag_list)).to be_falsey
    expect(extract.meets_service_requirements?(build(:ega_service), tag_list)).to be_falsey
    expect(extract.missing).to include('sample_taxon_id')
  end

  it 'should be able to create a list of tags from a hash of tags' do
    tags = build_list(:accession_tag, 5).index_by(&:name)
    tag_list = Accession::TagList.new(tags)
    expect(tag_list.count).to eq(tags.count)
  end
end
