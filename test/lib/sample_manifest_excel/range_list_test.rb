require 'test_helper'

class RangeListTest < ActiveSupport::TestCase
  include SampleManifestExcel::Helpers

  attr_reader :ranges, :range_list

  def setup
    folder = File.join('test', 'data', 'sample_manifest_excel')
    @ranges = load_file(folder, 'ranges')
    @range_list = SampleManifestExcel::RangeList.new(ranges)
  end

  test 'should create a list of ranges' do
    assert_equal ranges.count, range_list.count
  end

  test '#find_by returns correct range' do
    assert range_list.find_by(ranges.keys.first)
    assert range_list.find_by(ranges.keys.first.to_sym)
  end

  test '#set_worksheet_names should set worksheet names' do
    range_list.set_worksheet_names('Ranges').each do |_k, range|
      assert_equal 'Ranges', range.worksheet_name
    end
  end

  test 'should be comparable' do
    assert_equal range_list, SampleManifestExcel::RangeList.new(ranges)
  end
end
