# frozen_string_literal: true

require 'test_helper'

class SampleManifestUploadProcessorTubeRackTest < ActiveSupport::TestCase
  test 'generates valid row values' do
    results = SampleManifestExcel::Upload::Processor::TubeRack.generate_valid_row_values(5)
    puts results
    assert  results == ['A', 'B', 'C', 'D', 'E']
  end

  test 'validates coordinates' do
    rack_size = 96
    barcode_to_scan_results = {
      "AB12345678" => {
        "A1" => "BC12345678",
        "B2" => "CD12345678"
      },
      "YZ12345678" => {
        "A4" => "DE12345678",
        "B5" => "EF12345678"
      }
    }
    proc = SampleManifestExcel::Upload::Processor::TubeRack.new(SampleManifestExcel::Upload::Base.new())    # Difficulty with initialising - need to pass a file & maybe other things
    results = proc.validate_coordinates(rack_size, barcode_to_scan_results)
    assert  results == true
  end
end
