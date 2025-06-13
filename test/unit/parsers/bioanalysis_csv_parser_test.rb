# frozen_string_literal: true

require './test/test_helper'
require 'csv'

class BioanalysisCsvParserTest < ActiveSupport::TestCase
  def read_file(filename)
    content = nil
    File.open(filename, 'r') { |fd| content = fd.read }
    content
  end

  context 'Parser' do
    context 'With a valid csv file' do
      setup do
        @filename = Rails.root.join('test/data/bioanalysis_qc_results.csv').to_s
        @content = read_file @filename
        @csv = CSV.parse(@content)
      end

      should 'return a BioanalysisCsvParser' do
        assert Parsers.parser_for(@filename, nil, @content).is_a?(Parsers::BioanalysisCsvParser)
      end
    end

    context 'With an unreleated csv file' do
      setup do
        @filename = Rails.root.join('test/data/fluidigm.csv').to_s
        @content = read_file @filename
      end

      should 'not return a BioanalysisCsvParser' do
        assert_nil Parsers.parser_for(@filename, nil, @content)
      end
    end

    context 'with a non csv file' do
      setup do
        @filename = Rails.root.join('test/data/example_file.txt').to_s
        @content = read_file @filename
      end

      should 'return a BioanalysisCsvParser' do
        assert_nil Parsers.parser_for(@filename, nil, @content)
      end
    end
  end

  context 'A Bioanalysis parser of CSV' do
    context 'with a valid CSV biorobot file' do
      setup do
        filename = Rails.root.join('test/data/bioanalysis_qc_results.csv').to_s
        content = read_file filename

        @parser = Parsers::BioanalysisCsvParser.new(CSV.parse(content))
      end

      should 'return basic metadata' do
        assert_equal 'bioanalyser', @parser.assay_type
        assert_equal 'v0.1', @parser.assay_version
      end

      should 'parse last sample of testing file correctly' do
        assert_equal '1', @parser.parse_overall([157, 158])
      end

      should 'use get_groups method to find matching regexp' do
        test_data = [
          [24, 25],
          [37, 38],
          [49, 50],
          [61, 62],
          [73, 74],
          [85, 86],
          [97, 98],
          [109, 110],
          [121, 122],
          [133, 134],
          [145, 146],
          [157, 158]
        ]
        assert_equal test_data, @parser.get_groups(/Overall.*/m)
      end

      should 'parses a CSV example file' do
        assert_equal '25.65', @parser.concentration('A1')
        assert_equal '72.5', @parser.molarity('A1')
        assert_equal '18.06', @parser.concentration('B1')
        assert_equal '50.5', @parser.molarity('B1')
      end

      should 'map by well' do
        results = [
          ['A1', { 'concentration' => Unit.new('25.65 ng/ul'), 'molarity' => Unit.new('72.5 nmol/l') }],
          ['B1', { 'concentration' => Unit.new('18.06 ng/ul'), 'molarity' => Unit.new('50.5 nmol/l') }],
          ['C1', { 'concentration' => Unit.new('27.44 ng/ul'), 'molarity' => Unit.new('80.2 nmol/l') }],
          ['D1', { 'concentration' => Unit.new('26.69 ng/ul'), 'molarity' => Unit.new('77.6 nmol/l') }],
          ['E1', { 'concentration' => Unit.new('27.06 ng/ul'), 'molarity' => Unit.new('79.8 nmol/l') }],
          ['F1', { 'concentration' => Unit.new('17.60 ng/ul'), 'molarity' => Unit.new('50.2 nmol/l') }],
          ['G1', { 'concentration' => Unit.new('27.24 ng/ul'), 'molarity' => Unit.new('78.2 nmol/l') }],
          ['H1', { 'concentration' => Unit.new('15.67 ng/ul'), 'molarity' => Unit.new('43.9 nmol/l') }],
          ['A2', { 'concentration' => Unit.new('22.59 ng/ul'), 'molarity' => Unit.new('66.4 nmol/l') }],
          ['B2', { 'concentration' => Unit.new('26.26 ng/ul'), 'molarity' => Unit.new('77.2 nmol/l') }],
          ['C2', { 'concentration' => Unit.new('10.65 ng/ul'), 'molarity' => Unit.new('30.0 nmol/l') }],
          ['D2', { 'concentration' => Unit.new('25.38 ng/ul'), 'molarity' => Unit.new('73.2 nmol/l') }]
        ]
        @parser.each_well_and_parameters do |*args|
          assert results.delete(args).present?, "#{args.inspect} was an unexpected result"
        end
        assert results.empty?, "Some expected results were not returned: #{results.inspect}"
      end
    end
    context 'with an invalid CSV biorobot file' do
      setup do
        filename = "#{File.dirname(__FILE__)}/../../data/bioanalysis_qc_results-with-error.csv"
        content = read_file filename

        @parser = Parsers::BioanalysisCsvParser.new(CSV.parse(content))
      end

      should 'raise an exception while accessing any information' do
        assert_raises(Parsers::BioanalysisCsvParser::InvalidFile) { @parser.concentration('A1') }
      end
    end
  end
end
