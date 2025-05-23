# frozen_string_literal: true

require 'test_helper'
require_relative 'shared_tests'

class SampleManifestTubeTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedTubeTests

  attr_reader :manifest, :tube_label, :tube1, :tube2, :tube3, :tubes, :prefix, :barcode1, :label

  def setup # rubocop:todo Metrics/AbcSize, Metrics/MethodLength
    @manifest = create(:sample_manifest, asset_type: '1dtube', purpose: Tube::Purpose.standard_sample_tube, count: 3)
    @manifest.generate
    @tube1 = manifest.printables[0]
    @tube2 = manifest.printables[1]
    @tube3 = manifest.printables[2]
    @tubes = [tube1, tube2, tube3]

    @prefix = 'NT'
    @barcode1 = tube1.barcode_number

    options = { sample_manifest: @manifest, only_first_label: false }
    @tube_label = LabelPrinter::Label::SampleManifestTube.new(options)
    @label = {
      first_line: manifest.study.abbreviation.to_s,
      second_line: barcode1,
      third_line: Date.today.strftime('%e-%^b-%Y').to_s,
      round_label_top_line: prefix,
      round_label_bottom_line: barcode1,
      barcode: tube1.machine_barcode,
      label_name: 'main_label'
    }
  end

  test 'should return the right list of tubes' do
    assert_equal 3, tube_label.tubes.count
    assert_equal tubes, tube_label.assets
  end

  test 'returns only one tube if required to do so' do
    options = { sample_manifest: manifest, only_first_label: true }
    @tube_label = LabelPrinter::Label::SampleManifestTube.new(options)

    assert_equal 1, tube_label.tubes.count
    assert_equal manifest.printables.first, tube_label.tubes.first
  end

  test 'should return correct top line' do
    assert_equal manifest.study.abbreviation, tube_label.first_line
  end

  test 'should return the human barcode for 2D' do
    options = {
      sample_manifest: manifest,
      only_first_label: true,
      barcode_type: '2D Barcode (with human readable barcode encoded)'
    }
    @tube_label = LabelPrinter::Label::SampleManifestTube.new(options)

    assert_equal tube1.human_barcode, tube_label.barcode(tube1)
  end

  test 'should return the human barcode for 2D for library tubes' do
    @manifest = create(:sample_manifest, asset_type: 'library', purpose: Tube::Purpose.standard_sample_tube, count: 3)
    @manifest.generate
    @tube1 = manifest.printables[0]
    @tube2 = manifest.printables[1]
    @tube3 = manifest.printables[2]
    @tubes = [tube1, tube2, tube3]

    @prefix = 'NT'
    @barcode1 = tube1.barcode_number

    options = {
      sample_manifest: manifest,
      only_first_label: true,
      barcode_type: '2D Barcode (with human readable barcode encoded)'
    }
    @tube_label = LabelPrinter::Label::SampleManifestTube.new(options)

    assert_equal tube1.human_barcode, tube_label.barcode(tube1)
  end
end
