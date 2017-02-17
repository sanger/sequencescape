require 'rails_helper'

describe SampleManifestExcel::Tagging::Tags do
  # when we have a row it should work something like this:
  # if valid?
  #   update_tags
  # end
  #
  # def update_tags
  #   Tagging::Tags.new(self).update
  # end

  before(:all) do
    SampleManifestExcel.configuration.tag_group = 'Test group'
    Row = Struct.new(:sample_id, :tag_oligo, :tag2_oligo)
  end

  let!(:row) { Row.new('1', 'AA', 'TT') }
  let(:tags) { SampleManifestExcel::Tagging::Tags.new(row) }

  it 'should not be valid without an aliquot' do
    expect(tags.valid?).to be false
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

  it '#find_tag_by should find or create the right tag within the tag group' do
    number_of_tags = tags.tag_group.tags.count
    tag = tags.find_tag_by(oligo: 'ATT')
    expect(tags.tag_group.tags.count).to eq number_of_tags + 1
    expect(tag.oligo).to eq 'ATT'
    expect(tag.map_id).to eq number_of_tags + 1
    tags.find_tag_by(oligo: 'ATT')
    expect(tags.tag_group.tags.count).to eq number_of_tags + 1
  end
end
