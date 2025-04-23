# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Accession::Tag, :accession, type: :model do
  it 'onlies be valid with a name and groups' do
    expect(described_class.new(name: :tag_1, groups: :a)).to be_valid
    expect(described_class.new(name: :tag_1)).not_to be_valid
    expect(described_class.new(groups: :a)).not_to be_valid
  end

  it 'indicates which services it is required for' do
    tag = described_class.new(services: :ENA)
    expect(tag).to be_required_for(build(:ena_service))
    expect(tag).not_to be_required_for(build(:ega_service))

    tag = described_class.new(services: %i[ENA EGA])
    expect(tag).to be_required_for(build(:ena_service))
    expect(tag).to be_required_for(build(:ega_service))

    tag = described_class.new
    expect(tag).not_to be_required_for(build(:ena_service))
    expect(tag).not_to be_required_for(build(:ega_service))
  end

  it 'is able to add a value' do
    expect(described_class.new(value: 'Value 1').value).to eq('Value 1')
    expect(described_class.new.add_value('Value 2').value).to eq('Value 2')
    expect(described_class.new.add_value(2).value).to eq('2')
  end

  it 'can have an ebi name' do
    expect(described_class.new(ebi_name: :ebi_tag).ebi_name).to eq(:ebi_tag)
  end

  it 'has a label' do
    expect(described_class.new(name: :tag_1).label).to eq('tag 1')
    expect(described_class.new(name: :tag_1, ebi_name: :ebi_tag).label).to eq('ebi tag')
  end

  it 'can have an array express label' do
    expect(described_class.new(name: :tag_1).array_express_label).to eq('ArrayExpress-tag 1')
    expect(described_class.new(name: :tag_1, ebi_name: :ebi_tag).array_express_label).to eq('ArrayExpress-ebi tag')
  end

  it 'is comparable' do
    expect(build(:accession_tag)).to eq(build(:accession_tag)) # rubocop:todo RSpec/IdenticalEqualityAssertion
    expect(build(:sample_taxon_id_accession_tag)).not_to eq(build(:accession_tag))
  end
end
