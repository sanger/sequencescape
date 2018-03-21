require 'rails_helper'

RSpec.describe SampleManifestExcel::Cell, type: :model, sample_manifest_excel: true do
  it 'creates a row' do
    expect(SampleManifestExcel::Cell.new(1, 4).row).to eq(1)
  end

  it 'creates a column' do
    expect(SampleManifestExcel::Cell.new(1, 1).column).to eq('A')
    expect(SampleManifestExcel::Cell.new(1, 4).column).to eq('D')
    expect(SampleManifestExcel::Cell.new(1, 53).column).to eq('BA')
  end

  it 'creates a reference' do
    expect(SampleManifestExcel::Cell.new(150, 53).reference).to eq('BA150')
  end

  it 'creates a fixed reference' do
    expect(SampleManifestExcel::Cell.new(150, 53).fixed).to eq('$BA$150')
  end

  it 'is comparable' do
    expect(SampleManifestExcel::Cell.new(1, 1)).to eq(SampleManifestExcel::Cell.new(1, 1))
    expect(SampleManifestExcel::Cell.new(1, 1)).to_not eq(SampleManifestExcel::Cell.new(2, 1))
  end
end
