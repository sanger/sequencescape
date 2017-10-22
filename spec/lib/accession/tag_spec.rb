require 'rails_helper'

RSpec.describe Accession::Tag, type: :model, accession: true do
  it 'should only be valid with a name and groups' do
    expect(Accession::Tag.new(name: :tag_1, groups: :a)).to be_valid
    expect(Accession::Tag.new(name: :tag_1)).to_not be_valid
    expect(Accession::Tag.new(groups: :a)).to_not be_valid
  end

  it 'should indicate which services it is required for' do
    tag = Accession::Tag.new(services: :ENA)
    expect(tag.required_for?(build(:ena_service))).to be_truthy
    expect(tag.required_for?(build(:ega_service))).to be_falsey

    tag = Accession::Tag.new(services: [:ENA, :EGA])
    expect(tag.required_for?(build(:ena_service))).to be_truthy
    expect(tag.required_for?(build(:ega_service))).to be_truthy

    tag = Accession::Tag.new
    expect(tag.required_for?(build(:ena_service))).to be_falsey
    expect(tag.required_for?(build(:ega_service))).to be_falsey
  end

  it 'should be able to add a value' do
    expect(Accession::Tag.new(value: 'Value 1').value).to eq('Value 1')
    expect(Accession::Tag.new.add_value('Value 2').value).to eq('Value 2')
    expect(Accession::Tag.new.add_value(2).value).to eq('2')
  end

  it 'can have an ebi name' do
    expect(Accession::Tag.new(ebi_name: :ebi_tag).ebi_name).to eq(:ebi_tag)
  end

  it 'should have a label' do
    expect(Accession::Tag.new(name: :tag_1).label).to eq('TAG_1')
    expect(Accession::Tag.new(name: :tag_1, ebi_name: :ebi_tag).label).to eq('EBI_TAG')
  end

  it 'can have an array express label' do
    expect(Accession::Tag.new(name: :tag_1).array_express_label).to eq('ArrayExpress-TAG_1')
    expect(Accession::Tag.new(name: :tag_1, ebi_name: :ebi_tag).array_express_label).to eq('ArrayExpress-EBI_TAG')
  end

  it 'should be comparable' do
    expect(build(:accession_tag)).to eq(build(:accession_tag))
    expect(build(:sample_taxon_id_accession_tag)).to_not eq(build(:accession_tag))
  end
end
