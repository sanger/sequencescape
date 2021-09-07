# frozen_string_literal: true

require 'rails_helper'
require 'csv'

# Well Name	Live Count	Live Cells/mL	Live Mean Size	Viability	Dead Count	Dead Cells/mL	Dead Mean Size	Total Count	Total Cells/mL	Total Mean Size	Note:	Errors:
# A1	1074	2030000	9.35	75.00%	361	682000	2.36	1435	2710000	9.36		
# B1	1074	2030000	8.84	76.00%	341	644000	2.34	1415	2670000	9.06		
# C1	1218	2300000	8.81	75.00%	396	748000	2.21	1614	3050000	8.86		
# D1	1111	2100000	9.23	75.00%	371	700000	2.38	1482	2800000	9.31		
# E1	1208	2280000	8.77	75.00%	396	748000	2.3	1604	3030000	8.9		
# F1	1120	2110000	8.74	75.00%	377	712000	2.34	1497	2820000	8.88		
# G1	1177	2220000	8.79	76.00%	374	705000	2.14	1551	2930000	8.8		
# H1	1029	1940000	8.37	74.00%	357	675000	2.35	1386	2610000	8.57

def read_file(filename)
  content = nil
  File.open(filename, 'r') { |fd| content = fd.read }
  content
end

RSpec.describe Parsers::CardinalPbmcCountParser, type: :model do

  it 'will have an assay type' do
    expect(Parsers::CardinalPbmcCountParser.assay_type).to eq('Cardinal_PBMC_Count')
  end

  it 'will have an assay version' do
    expect(Parsers::CardinalPbmcCountParser.assay_version).to eq('v1.0')
  end

  context 'parse file' do

    let(:filename) { Rails.root.to_s + '/spec/data/parsers/cardinal_pbmc_count.csv' }
    let(:content) { read_file(filename) }

    it 'will have some content' do
      expect(Parsers::CardinalPbmcCountParser.new(content).content).to eq(content)
    end
   
  end
end


# class PlateReaderParserTest < ActiveSupport::TestCase
#   def read_file(filename)
#     content = nil
#     File.open(filename, 'r') { |fd| content = fd.read }
#     content
#   end

#   context 'Parser' do
#     context 'With a valid csv file' do
#       setup do
#         @filename = Rails.root.to_s + '/test/data/plate_reader_parsing_Zebrafish_example.csv'
#         @content = read_file @filename
#         @csv = CSV.parse(@content)
#       end

#       should 'return a Parsers::PlateReaderParser' do
#         assert_equal true, !Parsers.parser_for(@filename, nil, @content).nil?
#       end
#     end

#     context 'With an unreleated csv file' do
#       setup do
#         @filename = Rails.root.to_s + '/test/data/fluidigm.csv'
#         @content = read_file @filename
#       end

#       should 'not return a Parsers::PlateReaderParser' do
#         assert_nil Parsers.parser_for(@filename, nil, @content)
#       end
#     end

#     context 'with a non csv file' do
#       setup do
#         @filename = Rails.root.to_s + '/test/data/example_file.txt'
#         @content = read_file @filename
#       end

#       should 'not return a Parsers::PlateReaderParser' do
#         assert_nil Parsers.parser_for(@filename, nil, @content)
#       end
#     end
#   end

#   context 'A Parsers::PlateReaderParser parser of CSV' do
#     context 'with a valid CSV Parsers::PlateReaderParser file' do
#       setup do
#         filename = Rails.root.to_s + '/test/data/plate_reader_parsing_Zebrafish_example.csv'
#         content = read_file filename

#         @parser = Parsers::PlateReaderParser.new(CSV.parse(content))
#       end

#       should 'return basic metadata' do
#         assert_equal 'Plate Reader', @parser.assay_type
#         assert_equal 'v0.1', @parser.assay_version
#       end

#       should 'parses a CSV example file' do
#         assert_equal '75.783', @parser.concentration('A1')
#         assert_equal '70.487', @parser.concentration('B1')
#       end

#       should 'map by well' do
#         results = [
#           ['A1', { 'concentration' => Unit.new('75.783 ng/ul') }],
#           ['B1', { 'concentration' => Unit.new('70.487 ng/ul') }],
#           ['C1', { 'concentration' => Unit.new('78.785 ng/ul') }],
#           ['D1', { 'concentration' => Unit.new('59.62 ng/ul') }],
#           ['E1', { 'concentration' => Unit.new('38.78 ng/ul') }],
#           ['F1', { 'concentration' => Unit.new('34.294 ng/ul') }],
#           ['G1', { 'concentration' => Unit.new('25.496 ng/ul') }],
#           ['H1', { 'concentration' => Unit.new('32.952 ng/ul') }],
#           ['A2', { 'concentration' => Unit.new('76.92 ng/ul') }],
#           ['B2', { 'concentration' => Unit.new('29.055 ng/ul') }],
#           ['C2', { 'concentration' => Unit.new('76.69 ng/ul') }],
#           ['D2', { 'concentration' => Unit.new('80.721 ng/ul') }]
#         ]
#         @parser.each_well_and_parameters do |*args|
#           assert results.delete(args).present?, "#{args.inspect} was an unexpected result"
#         end
#         assert results.empty?, "Some expected results were not returned: #{results.inspect}"
#       end
#     end
#     context 'with an invalid CSV ISC file' do
#       setup do
#         filename = Rails.root.to_s + '/test/data/bioanalysis_qc_results-with-error.csv'
#         content = read_file filename

#         @parser = Parsers::PlateReaderParser.new(CSV.parse(content))
#       end

#       should 'raise an exception while accessing any information' do
#         assert_raises(Parsers::PlateReaderParser::InvalidFile) { @parser.concentration('A1') }
#       end
#     end
#   end
# end
