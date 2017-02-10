require 'test_helper'

class AttributesTest < ActiveSupport::TestCase
  attr_reader :sample

  def setup
    @sample = build(:sample_with_well)
  end

  test 'sanger plate id column should return sanger human barcode' do
    assert_equal sample.wells.first.plate.sanger_human_barcode, SampleManifestExcel::Attributes.find(:sanger_plate_id).value(sample)
  end

  test 'well column should return well description' do
    assert_equal sample.wells.first.map.description, SampleManifestExcel::Attributes.find(:well).value(sample)
  end

  test 'sanger sample id column should return sanger sample id of sample' do
    assert_equal sample.sanger_sample_id, SampleManifestExcel::Attributes.find(:sanger_sample_id).value(sample)
  end

  test 'donor id column should return sanger sample id' do
    assert_equal sample.sanger_sample_id, SampleManifestExcel::Attributes.find(:donor_id).value(sample)
  end

  test 'donor id 2 column should return sanger sample id' do
    assert_equal sample.sanger_sample_id, SampleManifestExcel::Attributes.find(:donor_id_2).value(sample)
  end

  test 'sanger tube id column should return sanger human barcode' do
    assert_equal sample.assets.first.sanger_human_barcode, SampleManifestExcel::Attributes.find(:sanger_tube_id).value(sample)
  end

  test 'column which has other attribute should return nothing' do
    assert_nil SampleManifestExcel::Attributes.find(:no_attribute_here).value(sample)
  end
end
