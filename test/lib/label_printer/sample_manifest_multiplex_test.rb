# frozen_string_literal: true

require 'test_helper'
require_relative 'shared_tests'

class SampleManifestMultiplexTest < ActiveSupport::TestCase
  include LabelPrinterTests::SharedTubeTests

  attr_reader :only_first_label, :manifest, :tube_label, :tube1, :prefix, :barcode1, :label, :study_abbreviation

  def setup # rubocop:todo Metrics/AbcSize
    @manifest = create :sample_manifest, asset_type: 'multiplexed_library', count: 3

    @manifest.generate

    @study_abbreviation = 'WTCCC'
    @prefix = 'NT'
    @tube1 = manifest.send(:core_behaviour).multiplexed_library_tube
    @barcode1 = tube1.barcode_number

    options = { sample_manifest: @manifest, only_first_label: false }
    @tube_label = LabelPrinter::Label::SampleManifestMultiplex.new(options)

    @label = {
      first_line: (study_abbreviation).to_s,
      middle_line: barcode1,
      bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
      round_label_top_line: prefix,
      round_label_bottom_line: barcode1,
      barcode: tube1.machine_barcode,
      label_name: 'main_label'
    }
  end

  test 'should return correct tubes' do
    assert_equal [tube1], tube_label.assets
  end

  test 'should return correct top line' do
    assert_equal study_abbreviation, tube_label.first_line
  end
end
