require 'test_helper'

class SampleManifestExcelTest < ActiveSupport::TestCase
  def setup
    SampleManifestExcel.configure do |config|
      config.folder = File.join('test', 'data', 'sample_manifest_excel')
      config.load!
    end
  end

  test 'should load the configuration' do
    assert SampleManifestExcel.configuration.loaded?
  end

  test 'configuration should be correct' do
    configuration = SampleManifestExcel::Configuration.new
    configuration.folder = File.join('test', 'data', 'sample_manifest_excel')
    configuration.load!
    assert_equal configuration, SampleManifestExcel.configuration
  end

  test '#reset should unload the configuration' do
    SampleManifestExcel.reset!
    refute SampleManifestExcel.configuration.loaded?
  end

  test 'should have a first row' do
    assert SampleManifestExcel.first_row
    SampleManifestExcel.first_row = 1
    assert_equal 1, SampleManifestExcel.first_row
  end

  def teardown
    SampleManifestExcel.reset!
  end
end
