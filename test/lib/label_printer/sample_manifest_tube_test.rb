require 'test_helper'
require_relative 'shared_tests'

class SampleManifestTubeTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedTubeTests

  attr_reader :manifest, :tube_label, :tube1, :tube2, :tube3, :tubes, :prefix, :barcode1, :label

  def setup
    @manifest = create :sample_manifest, asset_type: '1dtube', count: 3
    @manifest.generate

    @tube1 = manifest.samples.first.assets.first
    @tube2 = manifest.samples[1].assets.first
    @tube3 = manifest.samples[2].assets.first
    @tubes = [tube1, tube2, tube3]

    @prefix = 'NT'
    @barcode1 = tube1.barcode

    options = { sample_manifest: @manifest, only_first_label: false }
    @tube_label = LabelPrinter::Label::SampleManifestTube.new(options)
    @label = { top_line: (manifest.study.abbreviation).to_s,
               middle_line: barcode1,
               bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
               round_label_top_line: prefix,
               round_label_bottom_line: barcode1,
               barcode: tube1.ean13_barcode }
  end

  test 'should return the right list of tubes' do
    assert_equal 3, tube_label.tubes.count
    assert_equal tubes, tube_label.assets
  end

  test 'returns only one tube if required to do so' do
    options = { sample_manifest: manifest, only_first_label: true }
    @tube_label = LabelPrinter::Label::SampleManifestTube.new(options)

    assert_equal 1, tube_label.tubes.count
    assert_equal manifest.samples.first.assets.first, tube_label.tubes.first
  end

  test 'should return correct top line' do
    assert_equal manifest.study.abbreviation, tube_label.top_line
  end
end
