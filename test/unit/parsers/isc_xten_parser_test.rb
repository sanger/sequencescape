#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require File.dirname(__FILE__) + '/../../test_helper'

class IscXtenParserTest < ActiveSupport::TestCase

  def read_file(filename)
      fd = File.open(filename, "r")
      content = []
      while (line = fd.gets)
        content.push line
      end
      fd.close
      Iconv.conv('utf-8', 'WINDOWS-1253',content.join(""))
  end

  context "Parser" do
    context "With a valid csv file" do
      setup do
        @filename = File.dirname(__FILE__)+"/../../data/isc_xten_parsing_Zebrafish_example.csv"
        @content = read_file @filename
        @csv = FasterCSV.parse(@content)
      end

      should "return a Parsers::ISCXTenParser" do

        assert_equal true, (!Parsers.parser_for(@filename,nil,@content).nil?)
      end
    end

    context "With an unreleated csv file" do
      setup do
        @filename = File.dirname(__FILE__)+"/../../data/fluidigm.csv"
        @content = read_file @filename
      end

      should "return a Parsers::ISCXTenParser" do
        assert_equal nil, Parsers.parser_for(@filename,nil,@content)
      end
    end

    context "with a non csv file" do
      setup do
        @filename = File.dirname(__FILE__)+"/../../data/example_file.txt"
        @content = read_file @filename
      end

      should "return a Parsers::ISCXTenParser" do
        assert_equal nil, Parsers.parser_for(@filename,nil,@content)
      end
    end
  end

  context "A Parsers::ISCXTenParser parser of CSV" do
    context "with a valid CSV Parsers::ISCXTenParser file" do
      setup do
        filename = File.dirname(__FILE__)+"/../../data/isc_xten_parsing_Zebrafish_example.csv"
        content = read_file filename

        @parser = Parsers::ISCXTenParser.new(FasterCSV.parse(content))
      end

      #should "parse last sample of testing file correctly" do
      #  assert_equal "1", @parser.parse_overall([157,158])
      #end

      #should "use get_groups method to find matching regexp" do
      #  test_data = [[24, 25], [37, 38], [49, 50], [61, 62], [73, 74], [85, 86],
      #  [97, 98], [109, 110], [121, 122], [133, 134], [145, 146], [157,158]]
      #  assert_equal test_data, @parser.get_groups(/Overall.*/m)
      #end



      should "parses a CSV example file" do
        assert_equal "75.783", @parser.concentration("A1")
        assert_equal "70.487", @parser.concentration("B1")
      end

      should "map by well" do
        results = [
          ["A1","75.783"],
          ["B1","70.487"],
          ["C1","78.785"],
          ["D1","59.62"],
          ["E1","38.78"],
          ["F1","34.294"],
          ["G1","25.496"],
          ["H1","32.952"],
          ["A2","76.92"],
          ["B2","29.055"],
          ["C2","76.69"],
          ["D2","80.721"]
        ]
        results.each do |location, conc|
          assert_equal @parser.concentration(location), conc
        end
      end
    end
    context "with an invalid CSV ISC file" do
      setup do
        filename = File.dirname(__FILE__)+"/../../data/bioanalysis_qc_results-with-error.csv"
        content = read_file filename

        @parser = Parsers::ISCXTenParser.new(FasterCSV.parse(content))
      end

      should "raise an exception while accessing any information" do
        assert_raises(Parsers::ISCXTenParser::InvalidFile) { @parser.concentration("A1") }
      end
    end
  end
end
