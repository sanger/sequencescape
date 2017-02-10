require 'test_helper'

class CellTest < ActiveSupport::TestCase
  test 'should create a row' do
    assert_equal 1, SampleManifestExcel::Cell.new(1, 4).row
  end

  test 'should create a column' do
    assert_equal 'A', SampleManifestExcel::Cell.new(1, 1).column
    assert_equal 'D', SampleManifestExcel::Cell.new(1, 4).column
    assert_equal 'BA', SampleManifestExcel::Cell.new(1, 53).column
  end

  test 'should create a reference' do
    assert_equal 'BA150', SampleManifestExcel::Cell.new(150, 53).reference
  end

  test 'should create a fixed reference' do
    assert_equal '$BA$150', SampleManifestExcel::Cell.new(150, 53).fixed
  end

  test 'should be comparable' do
    assert_equal SampleManifestExcel::Cell.new(1, 1), SampleManifestExcel::Cell.new(1, 1)
    refute_equal SampleManifestExcel::Cell.new(1, 1), SampleManifestExcel::Cell.new(2, 1)
  end
end
