# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SequencescapeExcel::RangeList, :sample_manifest, :sample_manifest_excel, type: :model do
  include SequencescapeExcel::Helpers

  let(:folder) { File.join('spec', 'data', 'sample_manifest_excel') }
  let(:ranges) { load_file(folder, 'ranges') }
  let(:range_list) { described_class.new(ranges) }

  it 'will create a list of ranges' do
    expect(range_list.count).to eq(ranges.count)
  end

  it 'creates the right ranges' do
    static_range = range_list.find_by('gender')
    dynamic_range = range_list.find_by('reference_genome')
    expect(static_range).not_to be_dynamic
    assert static_range.static?
    assert static_range.name
    assert dynamic_range.dynamic?
    expect(dynamic_range).not_to be_static
    assert dynamic_range.name
  end

  it '#find_by returns correct range' do
    expect(range_list.find_by(ranges.keys.first)).not_to be_nil
    expect(range_list.find_by(ranges.keys.first.to_sym)).not_to be_nil
  end

  it '#set_worksheet_names will set worksheet names' do
    range_list.set_worksheet_names('Ranges').each { |_k, range| expect(range.worksheet_name).to eq('Ranges') }
  end

  it 'will be comparable' do
    expect(described_class.new(ranges)).to eq(range_list)
  end

  it 'has collected_by_for_cardinal ranges' do
    static_range = range_list.find_by('collected_by_for_cardinal')
    assert static_range.static?
    expect(static_range.name).to eq 'collected_by_for_cardinal'
    expect(static_range.options.count).to eq 6
  end

  it 'has collected_by_for_controls ranges' do
    static_range = range_list.find_by('collected_by_for_controls')
    assert static_range.static?
    expect(static_range.name).to eq 'collected_by_for_controls'
    expect(static_range.options.count).to eq 1
  end

  it 'has collected_by_for_scrna_core ranges' do
    static_range = range_list.find_by('collected_by_for_scrna_core')
    assert static_range.static?
    expect(static_range.name).to eq 'collected_by_for_scrna_core'
    expect(static_range.options.count).to eq 40
  end
end
