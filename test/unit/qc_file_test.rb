require File.dirname(__FILE__) + '/../test_helper'

class QcFileTest < ActiveSupport::TestCase

  context QcFile do

    context "with an asset" do
      setup do
        @plate = Factory :plate
        Parsers.expects(:parser_for).returns(:parser)
      end

      should "update the well concentration" do
        @plate.expects(:update_concentrations_from).with(:parser)
        QcFile.create!(:asset=>@plate)
      end
    end
  end

end
