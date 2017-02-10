require 'test_helper'

class ExampleLabel
  include LabelPrinter::Label::MultipleLabels

  attr_accessor :assets

  def create_label(asset)
    { left: asset.name,
      right: asset.prefix,
      barcode: asset.barcode }
  end
end

class ExampleLabelTest < ActiveSupport::TestCase
  attr_reader :example_label, :label, :labels, :plate1, :plate2, :plate3, :plate4

  def setup
    @example_label = ExampleLabel.new
    @plate1 = create :plate, name: 'Plate 1', barcode: '1111'
    @plate2 = create :plate, name: 'Plate 2', barcode: '2222'
    @plate3 = create :plate, name: 'Plate 3', barcode: '3333'
    @plate4 = create :plate, name: 'Plate 4', barcode: '4444'
    @label = { left: 'Plate 1',
               right: 'DN',
               barcode: '1111' }

    @labels = { body: [{ main_label:
                        { left: 'Plate 1',
                          right: 'DN',
                          barcode: '1111' }
                      },
                       { main_label:
                         { left: 'Plate 2',
                           right: 'DN',
                           barcode: '2222' }
                       },
                       { main_label:
                         { left: 'Plate 3',
                           right: 'DN',
                           barcode: '3333' }
                       },
                       { main_label:
                         { left: 'Plate 4',
                           right: 'DN',
                           barcode: '4444' }
                       }
              ] }
  end

  test 'should return the right label' do
    assert_equal ({ main_label: label }), example_label.label(plate1)
  end

  test 'should return the right labels' do
    assert_equal [], example_label.labels
    example_label.assets = [plate1, plate2, plate3, plate4]
    assert_equal labels, example_label.labels
    assert_equal ({ labels: labels }), example_label.to_h
  end

  test 'should return the right labels if count changes' do
    example_label.assets = [plate1]
    example_label.count = 3
    labels = { body: [{ main_label: label }, { main_label: label }, { main_label: label }] }
    assert_equal labels, example_label.labels
  end
end
