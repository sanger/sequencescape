require 'rails_helper'

describe SampleManifestExcel::Tagging::Tags do
  before(:all) do
    SampleManifestExcel.configuration.tag_group = 'Test group'
  end

  let(:tags) { SampleManifestExcel::Tagging::Tags.new(sample_id: '1', tag_oligo: 'AA', tag2_oligo: 'TT') }

  it 'should not be valid without an aliquot' do
    expect(tags).not_to be_valid
    expect(tags.errors.full_messages).to include "Aliquot can't be blank"
  end

  it 'should have a tag_group' do
    expect(tags.tag_group.name).to eq 'Test group'
  end

  it '#update should update tags in aliquot' do
    sample = create :sample_with_primary_aliquot, sanger_sample_id: '1'
    tags.update
    sample.reload
    expect(sample.primary_aliquot.tag.oligo).to eq 'AA'
    expect(sample.primary_aliquot.tag2.oligo).to eq 'TT'
  end

  it '#update should assign tag to nil if oligo was not provided' do
    sample = create :sample_with_primary_aliquot, sanger_sample_id: '1'
    tags = SampleManifestExcel::Tagging::Tags.new(sample_id: '1', tag_oligo: 'AA', tag2_oligo: nil)
    tags.update
    sample.reload
    expect(sample.primary_aliquot.tag.oligo).to eq 'AA'
    expect(sample.primary_aliquot.tag2).to eq nil
  end

  it '#find_tag_by should find or create the right tag within the tag group' do
    number_of_tags = tags.tag_group.tags.count
    tag = tags.find_tag_by(oligo: 'ATT')
    expect(tags.tag_group.tags.count).to eq number_of_tags + 1
    expect(tag.oligo).to eq 'ATT'
    expect(tag.map_id).to eq number_of_tags + 1
    tags.find_tag_by(oligo: 'ATT')
    expect(tags.tag_group.tags.count).to eq number_of_tags + 1
    tags.find_tag_by(oligo: nil)
    expect(tags.tag_group.tags.count).to eq number_of_tags + 1
  end
end
