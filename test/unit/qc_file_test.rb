#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
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
