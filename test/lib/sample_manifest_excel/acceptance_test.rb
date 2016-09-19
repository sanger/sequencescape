require_relative '../../test_helper'

class AcceptanceTest < ActiveSupport::TestCase

  attr_reader :download, :sample_manifest

  def setup

    SampleManifestExcel.configure do |config|
      config.folder = File.join("test","data", "sample_manifest_excel", "extract")
      config.load!
    end

    @sample_manifest = create(:sample_manifest_with_samples)

    @download = SampleManifestExcel::Download.new(sample_manifest,
        SampleManifestExcel.configuration.columns.test.dup,
        SampleManifestExcel.configuration.ranges.dup)
    download.save('test.xlsx')
  end

  test "should create a worksheet" do
    assert File.file?('test.xlsx')
    assert download.password
  end

  def teardown
    SampleManifestExcel.reset!
  end

end
