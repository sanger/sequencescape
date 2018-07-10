# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SampleManifestExcel::RangeList, type: :model, sample_manifest_excel: true do
  include SampleManifestExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:ranges) { load_file(folder, 'ranges') }
  let(:range_list) { SampleManifestExcel::RangeList.new(ranges) }

  it 'will create a list of ranges' do
    expect(range_list.count).to eq(ranges.count)
  end

  it 'should create the right ranges' do
    static_range = range_list.first[1]
    dynamic_range = range_list.find_by(ranges.keys.last)
    refute static_range.dynamic?
    assert static_range.static?
    assert static_range.name
    assert dynamic_range.dynamic?
    refute dynamic_range.static?
    assert dynamic_range.name
  end

  it '#find_by returns correct range' do
    expect(range_list.find_by(ranges.keys.first)).to_not be_nil
    expect(range_list.find_by(ranges.keys.first.to_sym)).to_not be_nil
  end

  it '#set_worksheet_names will set worksheet names' do
    range_list.set_worksheet_names('Ranges').each do |_k, range|
      expect(range.worksheet_name).to eq('Ranges')
    end
  end

  it 'will be comparable' do
    expect(SampleManifestExcel::RangeList.new(ranges)).to eq(range_list)
  end
end
