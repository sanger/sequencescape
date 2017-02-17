require 'rails_helper'

describe SampleManifestExcel::Tagging::TagsUpdate do

  # when we have a row it should work something like this:
  # if valid?
  #   update_tags
  # end
  #
  # def update_tags
  #   Tagging::TagsUpdate.new(self)
  # end

  before (:all) do
    SampleManifestExcel.configuration.tag_group = 'Test group'
    Row = Struct.new(:sample_id, :tag_oligo, :tag2_oligo)
  end

  let!(:row) { Row.new('1', 'AA', 'TT') }
  let(:tags_update) { SampleManifestExcel::Tagging::TagsUpdate.new(row) }

  it 'should not be valid without an aliquot' do
    expect(tags_update.valid?).to be false
  end

  it 'should have a tag_group' do
    expect(tags_update.tag_group.name).to eq 'Test group'
  end

  it 'should execute update of tags in aliquots' do
    sample = create :sample_with_primary_aliquot, sanger_sample_id: '1'
    tags_update.execute
    sample = Sample.find_by(sanger_sample_id: '1')
    expect(sample.primary_aliquot.tag.oligo).to eq 'AA'
    expect(sample.primary_aliquot.tag2.oligo).to eq 'TT'
  end

  it '#find_tag_by should find or create the right tag within the tag group' do
    number_of_tags = tags_update.tag_group.tags.count
    tag = tags_update.find_tag_by(oligo: 'ATT')
    expect(tags_update.tag_group.tags.count).to eq number_of_tags + 1
    expect(tag.oligo).to eq 'ATT'
    expect(tag.map_id).to eq number_of_tags + 1
    tags_update.find_tag_by(oligo: 'ATT')
    expect(tags_update.tag_group.tags.count).to eq number_of_tags + 1
  end

end