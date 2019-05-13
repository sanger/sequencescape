require 'rails_helper'

RSpec.describe Accession::Tag, type: :model, accession: true do
  it 'onlies be valid with a name and groups' do
    expect(Accession::Tag.new(name: :tag_1, groups: :a)).to be_valid
    expect(Accession::Tag.new(name: :tag_1)).not_to be_valid
    expect(Accession::Tag.new(groups: :a)).not_to be_valid
  end

  it 'indicates which services it is required for' do
    tag = Accession::Tag.new(services: :ENA)
    expect(tag).to be_required_for(build(:ena_service))
    expect(tag).not_to be_required_for(build(:ega_service))

    tag = Accession::Tag.new(services: [:ENA, :EGA])
    expect(tag).to be_required_for(build(:ena_service))
    expect(tag).to be_required_for(build(:ega_service))

    tag = Accession::Tag.new
    expect(tag).not_to be_required_for(build(:ena_service))
    expect(tag).not_to be_required_for(build(:ega_service))
  end

  it 'is able to add a value' do
    expect(Accession::Tag.new(value: 'Value 1').value).to eq('Value 1')
    expect(Accession::Tag.new.add_value('Value 2').value).to eq('Value 2')
    expect(Accession::Tag.new.add_value(2).value).to eq('2')
  end

  it 'can have an ebi name' do
    expect(Accession::Tag.new(ebi_name: :ebi_tag).ebi_name).to eq(:ebi_tag)
  end

  it 'has a label' do
    expect(Accession::Tag.new(name: :tag_1).label).to eq('TAG_1')
    expect(Accession::Tag.new(name: :tag_1, ebi_name: :ebi_tag).label).to eq('EBI_TAG')
  end

  it 'can have an array express label' do
    expect(Accession::Tag.new(name: :tag_1).array_express_label).to eq('ArrayExpress-TAG_1')
    expect(Accession::Tag.new(name: :tag_1, ebi_name: :ebi_tag).array_express_label).to eq('ArrayExpress-EBI_TAG')
  end

  it 'is comparable' do
    expect(build(:accession_tag)).to eq(build(:accession_tag))
    expect(build(:sample_taxon_id_accession_tag)).not_to eq(build(:accession_tag))
  end
end
