require 'test_helper'

class RangeListTest < ActiveSupport::TestCase

  attr_reader :ranges, :range_list

  def setup
    @ranges = {yes_no: ['yes', 'no'], gender: ['Male', 'Female', 'Mixed', 'Hermaphrodite', 'Unknown', 'Not Applicable'], concentration_determined_by: ['PicoGreen', 'Nanodrop', 'Spectrophotometer', 'Other']}
    @range_list = SampleManifestExcel::RangeList.new(ranges)
  end

  test 'should create a list of ranges' do
    assert_equal ranges.count, range_list.count
  end

  test "#find_by returns correct range" do
    assert range_list.find_by(ranges.keys.first)
  end

  test "each range should have a position" do
    ranges.each_with_index do |(range, v), i|
      assert_equal i+1,range_list.find_by(range).position
    end
  end

end