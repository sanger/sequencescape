require './test/test_helper'
require 'csv'

class QuantParserTest < ActiveSupport::TestCase
  def read_file(filename)
    content = nil
    File.open(filename, 'r') do |fd|
      content = fd.read
    end
    content
  end

  context 'Parser' do
    context 'With a valid csv file' do
      setup do
        @filename = Rails.root.to_s + '/test/data/quant_test.csv'
        @content = read_file @filename

        # We WANT to be using this encoding here. So if this line starts failing, fix the encoding in
        # the actual file.
        @csv = CSV.parse(@content.force_encoding('iso-8859-1'))
      end

      should 'return a QuantParser' do
        assert Parsers.parser_for(@filename, nil, @content).is_a?(Parsers::QuantParser)
      end

      context 'processing the file' do
        setup do
          @parser = Parsers.parser_for(@filename, nil, @content)
          @barcode = '999991'
          @plate = PlatePurpose.find_by(name: 'Stock Plate').plates.create!
          @plate.update_attributes(barcode: @barcode)
          @plate.wells.construct!
          @plate.wells.each do |well|
            well.set_concentration(30)
          end
          @plate.update_qc_values_with_parser(@parser)
        end

        should 'update well attributes with the file contents' do
          [['A1', 35, 7.5],
           ['A2', 56, 8.1],
           ['A3', 89, 4.3]].each do |location, concentration, _rin|
              assert_equal concentration, @plate.wells.located_at(location).first.get_concentration
          end
        end
        should 'not update attributes for lines without content' do
          assert_equal 30, @plate.wells.located_at('B1').first.get_concentration
          assert_equal 30, @plate.wells.located_at('B2').first.get_concentration
          assert_equal 30, @plate.wells.located_at('B3').first.get_concentration
        end
      end
    end

    context 'With an actual example csv file' do
      setup do
        @filename = Rails.root.to_s + '/test/data/quant_test_example.csv'
        @content = read_file @filename

        # We WANT to be using this encoding here. So if this line starts failing, fix the encoding in
        # the actual file.
        @csv = CSV.parse(@content.force_encoding('iso-8859-1'))
      end

      should 'return a QuantParser' do
        assert Parsers.parser_for(@filename, nil, @content).is_a?(Parsers::QuantParser)
      end

      context 'processing the file' do
        setup do
          @parser = Parsers.parser_for(@filename, nil, @content)
          @barcode = '999991'
          @plate = PlatePurpose.find_by(name: 'Stock Plate').plates.create!
          @plate.update_attributes(barcode: @barcode)
          @plate.wells.construct!
          @plate.wells.each do |well|
            well.set_concentration(30)
          end
          @plate.update_qc_values_with_parser(@parser)
        end

        should 'update well attributes with the file contents' do
          [['A1', 134.47, 7.5],
           ['A2', 81.96, 8.1],
           ['A3', 36.76, 4.3]].each do |location, concentration, _rin|
              assert_equal concentration, @plate.wells.located_at(location).first.get_concentration
          end
        end
      end
    end

    context 'with an invalid csv file' do
      setup do
        @filename = Rails.root.to_s + '/test/data/invalid_quant_test.csv'
        @content = read_file @filename
        @csv = CSV.parse(@content)
      end

      should 'detect that the format is not correct' do
        refute Parsers::QuantParser.is_quant_file?(@csv)
      end
    end
  end
end
