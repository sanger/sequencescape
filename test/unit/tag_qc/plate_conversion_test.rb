#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2014 Genome Research Ltd.
require "test_helper"

class PlateConversionTest < ActiveSupport::TestCase
  context "A Plate Conversion" do

    should_belong_to :user
    should_belong_to :target
    should_belong_to :purpose


    context "#stamp" do
      should 'convert plates to a new purpose' do
        @plate = Factory :plate
        @user  = Factory :user
        @purpose_b = PlatePurpose.new(:name=>'test_purpose')

        PlateConversion.create!(:target=>@plate,:user=>@user,:purpose=>@purpose_b)

        assert_equal @purpose_b, @plate.purpose

      end

      should 'set parents when supplied' do
        @plate = Factory :plate
        @parent = Factory :plate
        @user  = Factory :user
        @purpose_b = PlatePurpose.new(:name=>'test_purpose')

        PlateConversion.create!(:target=>@plate,:user=>@user,:purpose=>@purpose_b,:parent=>@parent)

        assert_equal @parent, @plate.parents.first

      end
    end
  end

end
