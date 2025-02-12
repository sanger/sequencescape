RSpec.shared_examples 'a tag group' do |tag_group_name|
  it 'will add the value' do
    sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)
    expect(sf_tag_group.value).to eq(tag_group_name)
  end

  it 'will be valid with an existing tag group name' do
    sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)
    expect(sf_tag_group).to be_valid
  end

  context 'when the tag group is not Chromium' do
    let(:adapter_type) { create(:adapter_type, name: 'Other') }

    it 'will not be valid' do
      expect(described_class.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)).not_to be_valid
    end
  end

  it 'responds to update method but does nothing to tag on aliquot' do
    sf_tag_group = described_class.new(value: tag_group_name, sample_manifest_asset: sample_manifest_asset)
    expect(sf_tag_group.update(aliquot: aliquot, tag_group: nil)).to be_nil
    aliquot.save
    expect(aliquot.tag).to be_nil
  end
end
