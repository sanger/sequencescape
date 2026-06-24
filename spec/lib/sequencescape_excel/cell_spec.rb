# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::Cell, :sample_manifest, :sample_manifest_excel, type: :model do
  it 'creates a row' do
    expect(described_class.new(1, 4).row).to eq(1)
  end

  it 'creates a column' do
    expect(described_class.new(1, 1).column).to eq('A')
    expect(described_class.new(1, 4).column).to eq('D')
    expect(described_class.new(1, 53).column).to eq('BA')
  end

  it 'creates a reference' do
    expect(described_class.new(150, 53).reference).to eq('BA150')
  end

  it 'creates a fixed reference' do
    expect(described_class.new(150, 53).fixed).to eq('$BA$150')
  end

  it 'is comparable' do
    expect(described_class.new(1, 1)).to eq(described_class.new(1, 1)) # rubocop:todo RSpec/IdenticalEqualityAssertion
    expect(described_class.new(1, 1)).not_to eq(described_class.new(2, 1))
  end
end
