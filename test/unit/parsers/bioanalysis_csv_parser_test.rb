require File.dirname(__FILE__) + '/../../test_helper'

class BionanalysisCsvParserTest < ActiveSupport::TestCase
  context "A Bioanalysis parser of CVS" do
    setup do
      filename = File.dirname(__FILE__)+"/../../data/DN123456_DNA 1000_DE72902958_2014-10-09_11-18-00_Results.csv"
      fd = File.open(filename, "r")
      content = []
      while (line = fd.gets) 
        content.push line
      end
      fd.close
      # <ruby-1.9>content.join("").force_encoding("ISO-8859-1").encode("UTF-8")</ruby-1.9>
      content = Iconv.conv('utf-8', 'WINDOWS-1253',content.join(""))

      @parser = Parsers::BioanalysisCsvParser.new(filename, content)
    end

    should "checks a file has correct type" do
      assert_equal @parser.validates_content?, true
    end

    should "parses a CSV example file" do
      assert_equal @parser.concentration("A1"), "25.65"
    end
  end
end