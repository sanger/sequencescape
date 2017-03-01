require 'rails_helper'

describe SampleManifestExcel::Tagging::Validation, type: :model, sample_manifest_excel: true do
  class SomeData
    include SampleManifestExcel::Tagging::Validation
  end

  let(:data) { SomeData.new }
  let(:tags_oligos) { %w(A AA T AA) }
  let(:tags2_oligos) { %w(A A A A) }

  it 'should not be valid without tags_oligos and tags2_oligos' do
    expect(data).to_not be_valid
    expect(data.errors.messages.length).to eq 2
  end

  it 'should not be valid if tags combinations are not unique' do
    data.tags_oligos = tags_oligos
    data.tags2_oligos = tags2_oligos
    expect(data).to_not be_valid
    expect(data.errors.messages.length).to eq 1
    expect(data.errors.full_messages).to include 'Tags combinations are not unique'
  end

  it 'should be valid if tags combinations are unique' do
    data.tags_oligos = tags_oligos.first(3)
    data.tags2_oligos = tags2_oligos.first(3)
    expect(data).to be_valid
  end
end
