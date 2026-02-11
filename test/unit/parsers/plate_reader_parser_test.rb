# frozen_string_literal: true

require './test/test_helper'
require 'csv'

class PlateReaderParserTest < ActiveSupport::TestCase
  def read_file(filename)
    content = nil
    File.open(filename, 'r') { |fd| content = fd.read }
    content
  end

  context 'Parser' do
    context 'With a valid csv file' do
      setup do
        @filename = Rails.root.join('test/data/plate_reader_parsing_Zebrafish_example.csv').to_s
        @content = read_file @filename
        @csv = CSV.parse(@content)
      end

      should 'return a Parsers::PlateReaderParser' do
        assert_equal true, !Parsers.parser_for(@filename, nil, @content).nil?
      end
    end

    context 'With an unreleated csv file' do
      setup do
        @filename = Rails.root.join('test/data/fluidigm.csv').to_s
        @content = read_file @filename
      end

      should 'not return a Parsers::PlateReaderParser' do
        assert_nil Parsers.parser_for(@filename, nil, @content)
      end
    end

    context 'with a non csv file' do
      setup do
        @filename = Rails.root.join('test/data/example_file.txt').to_s
        @content = read_file @filename
      end

      should 'not return a Parsers::PlateReaderParser' do
        assert_nil Parsers.parser_for(@filename, nil, @content)
      end
    end
  end

  context 'A Parsers::PlateReaderParser parser of CSV' do
    context 'with a valid CSV Parsers::PlateReaderParser file' do
      setup do
        filename = Rails.root.join('test/data/plate_reader_parsing_Zebrafish_example.csv').to_s
        content = read_file filename

        @parser = Parsers::PlateReaderParser.new(CSV.parse(content))
      end

      should 'return basic metadata' do
        assert_equal 'Plate Reader', @parser.assay_type
        assert_equal 'v0.1', @parser.assay_version
      end

      should 'parses a CSV example file' do
        assert_equal '75.783', @parser.concentration('A1')
        assert_equal '70.487', @parser.concentration('B1')
      end

      should 'map by well' do
        results = [
          ['A1', { 'concentration' => Unit.new('75.783 ng/ul') }],
          ['B1', { 'concentration' => Unit.new('70.487 ng/ul') }],
          ['C1', { 'concentration' => Unit.new('78.785 ng/ul') }],
          ['D1', { 'concentration' => Unit.new('59.62 ng/ul') }],
          ['E1', { 'concentration' => Unit.new('38.78 ng/ul') }],
          ['F1', { 'concentration' => Unit.new('34.294 ng/ul') }],
          ['G1', { 'concentration' => Unit.new('25.496 ng/ul') }],
          ['H1', { 'concentration' => Unit.new('32.952 ng/ul') }],
          ['A2', { 'concentration' => Unit.new('76.92 ng/ul') }],
          ['B2', { 'concentration' => Unit.new('29.055 ng/ul') }],
          ['C2', { 'concentration' => Unit.new('76.69 ng/ul') }],
          ['D2', { 'concentration' => Unit.new('80.721 ng/ul') }]
        ]

        @parser.each_well_and_parameters do |*args|
          assert_predicate results.delete(args), :present?, "#{args.inspect} was an unexpected result"
        end
        assert_empty results, "Some expected results were not returned: #{results.inspect}"
      end
    end
    context 'with an invalid CSV ISC file' do
      setup do
        filename = Rails.root.join('test/data/bioanalysis_qc_results-with-error.csv').to_s
        content = read_file filename

        @parser = Parsers::PlateReaderParser.new(CSV.parse(content))
      end

      should 'raise an exception while accessing any information' do
        assert_raises(Parsers::PlateReaderParser::InvalidFile) { @parser.concentration('A1') }
      end
    end
  end
end
