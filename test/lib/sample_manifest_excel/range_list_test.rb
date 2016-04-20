require 'test_helper'

class RangeListTest < ActiveSupport::TestCase

  attr_reader :ranges, :range_list

  def setup
    @ranges = YAML::load_file(File.expand_path(File.join(Rails.root,"test","data", "sample_manifest_excel","sample_manifest_validation_ranges_short.yml")))
    @range_list = SampleManifestExcel::RangeList.new(ranges)
  end

  test 'should create a list of ranges' do
    assert_equal ranges.count, range_list.count
  end

  test "#find_by returns correct range" do
    assert range_list.find_by(ranges.keys.first)
  end

  test "#set_absolute_references should set absolute references to ranges" do
    worksheet = build :worksheet
    range_list.set_absolute_references(worksheet)
    range = range_list.ranges.values.first
    assert_equal "#{worksheet.name}!#{range.reference}", range.absolute_reference
    assert range_list.all? {|k, range| range.absolute_reference.present?}
  end

end