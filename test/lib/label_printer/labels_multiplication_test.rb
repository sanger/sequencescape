# frozen_string_literal: true

require 'test_helper'

class ExampleLabel
  include LabelPrinter::Label::MultipleLabels

  attr_accessor :assets

  def build_label(asset)
    { left: asset.name, right: asset.prefix, barcode: asset.barcode_number, label_name: 'main_label' }
  end
end

class ExampleLabelTest < ActiveSupport::TestCase
  attr_reader :example_label, :label, :labels, :plate1, :plate2, :plate3, :plate4

  def setup
    @example_label = ExampleLabel.new
    @plate1 = create(:plate, name: 'Plate 1', barcode: 'SQPD-1111')
    @plate2 = create(:plate, name: 'Plate 2', barcode: 'SQPD-2222')
    @plate3 = create(:plate, name: 'Plate 3', barcode: 'SQPD-3333')
    @plate4 = create(:plate, name: 'Plate 4', barcode: 'SQPD-4444')
    @label = { left: 'Plate 1', right: 'SQPD', barcode: '1111', label_name: 'main_label' }

    @labels = [
      { left: 'Plate 1', right: 'SQPD', barcode: '1111', label_name: 'main_label' },
      { left: 'Plate 2', right: 'SQPD', barcode: '2222', label_name: 'main_label' },
      { left: 'Plate 3', right: 'SQPD', barcode: '3333', label_name: 'main_label' },
      { left: 'Plate 4', right: 'SQPD', barcode: '4444', label_name: 'main_label' }
    ]
  end

  test 'should return the right label' do
    assert_equal label, example_label.build_label(plate1)
  end

  test 'should return the right labels' do
    assert_empty example_label.labels
    example_label.assets = [plate1, plate2, plate3, plate4]

    assert_equal labels, example_label.labels
  end

  test 'should return the right labels if count changes' do
    example_label.assets = [plate1]
    example_label.count = 3
    labels = [label, label, label]

    assert_equal labels, example_label.labels
  end
end
