require 'rails_helper'

describe SampleManifestExcel::TagsUpdate do

  let!(:sanger_sample_ids) { ['1', '2', '3'] }
  let!(:tag1_oligos) { ['A', 'AA', 'T', 'AA'] }
  let!(:tag2_oligos) { ['A', 'A', 'A', 'A'] }
  let(:invalid_tags_update) { SampleManifestExcel::TagsUpdate.new(sanger_sample_ids: sanger_sample_ids, tag1_oligos: tag1_oligos, tag2_oligos: tag2_oligos) }
  let(:tags_update) { SampleManifestExcel::TagsUpdate.new(sanger_sample_ids: sanger_sample_ids, tag1_oligos: tag1_oligos.first(3), tag2_oligos: tag2_oligos.first(3)) }

  it 'should be invalid if combination of tag1 and tag2 is not unique, number of samples does not correspond to number of tags' do
    expect(invalid_tags_update.valid?).to be false
    expect(invalid_tags_update.errors.messages.length).to eq 2
  end

  it 'should be valid if tags combinations are unique and number of samples equals to number of tags' do
    expect(tags_update.valid?).to be true
    expect(tags_update.tag_group.name).to eq 'Main'
  end

  it 'should execute update of tags in aliquots' do
    samples = create_list(:sample_with_primary_aliquot, 3)
    samples.each_with_index {|sample, index| sample.sanger_sample_id = sanger_sample_ids[index]; sample.save}
    tags_update.execute
    sanger_sample_ids.each_with_index do |sample_id, index|
      sample = Sample.find_by(sanger_sample_id: sample_id)
      expect(sample.primary_aliquot.tag.oligo).to eq tag1_oligos[index]
      expect(sample.primary_aliquot.tag2.oligo).to eq tag2_oligos[index]
    end
  end

  it '#find_tag_by should find or create the right tag within the tag group' do
    number_of_tags = tags_update.tag_group.tags.count
    tag = tags_update.find_tag_by(oligo: 'ATT')
    expect(tags_update.tag_group.tags.count).to eq number_of_tags+1
    expect(tag.oligo).to eq 'ATT'
    expect(tag.map_id).to eq number_of_tags+1
    tags_update.find_tag_by(oligo: 'ATT')
    expect(tags_update.tag_group.tags.count).to eq number_of_tags+1
  end

end