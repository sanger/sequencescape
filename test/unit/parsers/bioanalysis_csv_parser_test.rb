require File.dirname(__FILE__) + '/../../test_helper'

class BionanalysisCsvParserTest < ActiveSupport::TestCase
  def read_file(filename)
      fd = File.open(filename, "r")
      content = []
      while (line = fd.gets) 
        content.push line
      end
      fd.close
      Iconv.conv('utf-8', 'WINDOWS-1253',content.join(""))
  end

  context "A Bioanalysis parser of CSV" do
    context "with a valid CSV biorobot file" do
      setup do
        filename = File.dirname(__FILE__)+"/../../data/bioanalysis_qc_results.csv"
        # <ruby-1.9>content.join("").force_encoding("ISO-8859-1").encode("UTF-8")</ruby-1.9>
        content = read_file filename

        @parser = Parsers::BioanalysisCsvParser.new(filename, content)
      end

      should "checks a file has correct type" do
        assert_equal @parser.validates_content?, true
      end

      should "parses a CSV example file" do
        assert_equal @parser.concentration("A1"), "25.65"
      end
    end
    context "with an invalid CSV biorobot file" do
      setup do
        filename = File.dirname(__FILE__)+"/../../data/bioanalysis_qc_results-with-error.csv"
        # <ruby-1.9>content.join("").force_encoding("ISO-8859-1").encode("UTF-8")</ruby-1.9>
        content = read_file filename

        @parser = Parsers::BioanalysisCsvParser.new(filename, content)
      end
      should "checks a file has incorrect type" do
        assert_equal @parser.validates_content?, false
      end

      should "return nil while accessing any information" do
        assert_equal @parser.concentration("A1"), nil
      end
    end
  end
end