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

end