require 'rails_helper'

describe SampleManifestExcel::Tagging::TagsDataValidation do
  class SomeData
    include SampleManifestExcel::Tagging::TagsDataValidation
  end

  let(:data) { SomeData.new }
  let(:tags_oligos) { %w(A AA T AA) }
  let(:tags2_oligos) { %w(A A A A) }

  it 'should not be valid without tags_oligos and tags2_oligos' do
    expect(data.valid?).to be false
    expect(data.errors.messages.length).to eq 2
  end

  it 'should not be valid if tags combinations are not unique' do
    data.tags_oligos = tags_oligos
    data.tags2_oligos = tags2_oligos
    expect(data.valid?).to be false
    expect(data.errors.messages.length).to eq 1
    expect(data.errors.full_messages).to include 'Tags combinations are not unique'
  end

  it 'should be valid if tags combinations are unique' do
    data.tags_oligos = tags_oligos.first(3)
    data.tags2_oligos = tags2_oligos.first(3)
    expect(data.valid?).to be true
  end
end
