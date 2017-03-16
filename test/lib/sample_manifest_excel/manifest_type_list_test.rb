require 'test_helper'

class ManifestTypeListTest < ActiveSupport::TestCase
  include SampleManifestExcel::Helpers

  attr_reader :yaml, :manifest_type_list

  def setup
    folder = File.join('test', 'data', 'sample_manifest_excel', 'extract')
    @yaml = load_file(folder, 'manifest_types')
    @manifest_type_list = SampleManifestExcel::ManifestTypeList.new(yaml)
  end

  test 'should create a list of manifest types' do
    assert_equal yaml.length, manifest_type_list.count
  end

  test 'each manifest type should have the correct attributes' do
    yaml.each do |k, v|
      manifest_type = manifest_type_list.find_by(k)
      assert_equal k, manifest_type.name
      assert_equal v['heading'], manifest_type.heading
      assert_equal v['columns'], manifest_type.columns
      assert_equal v['asset_type'], manifest_type.asset_type
    end
  end

  test '#to_a should produce a list of headings and names' do
    names_and_headings = manifest_type_list.to_a
    assert_equal yaml.length, names_and_headings.count
    yaml.each do |k, v|
      assert names_and_headings.include? [v['heading'], k]
    end
  end

  test '#by_asset_type should return a list of manifest types by their asset type' do
    assert_equal 2, manifest_type_list.by_asset_type('plate').count
    assert_equal 1, manifest_type_list.by_asset_type('tube').count
    refute manifest_type_list.by_asset_type('dodgy asset type').any?
    assert_equal manifest_type_list.count, manifest_type_list.by_asset_type(nil).count
  end

  test 'should be comparable' do
    assert_equal SampleManifestExcel::ManifestTypeList.new(yaml), manifest_type_list
    yaml.shift
    refute_equal SampleManifestExcel::ManifestTypeList.new(yaml), manifest_type_list
  end
end
