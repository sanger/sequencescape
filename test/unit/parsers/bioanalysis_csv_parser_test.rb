require File.dirname(__FILE__) + '/../../test_helper'

class BionanalysisCsvParserTest < ActiveSupport::TestCase
  context "A Bioanalysis parser of CVS" do
    setup do
      @parser = Parsers::BioanalysisCsvParser.new(File.dirname(__FILE__)+"/../../data/DN123456_DNA 1000_DE72902958_2014-10-09_11-18-00_Results.csv")
    end

    should "checks a file has correct type" do
      assert_equal @parser.validates_content?, true
    end

    should "parses a CSV example file" do
      assert_equal @parser.concentration("A1"), "25.65"
    end
  end
end