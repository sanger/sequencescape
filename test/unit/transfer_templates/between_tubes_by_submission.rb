#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require "test_helper"

class TransferBetweenTubesBySubmissionTest < ActiveSupport::TestCase

  context "A transfer between tubes by submission" do

    setup do
      @user    = Factory :user

      @tube_a  = Factory :new_stock_multiplexed_library_tube
      @plate_transfer_a = Factory :transfer_from_plate_to_tube, :destination => @tube_a
      @plate_a = @plate_transfer_a.source
      @submission = Factory :submission_without_order

      @final_tube = Factory :multiplexed_library_tube

      @tube_a.purpose.child_relationships.create!(:child => @final_tube.purpose, :transfer_request_type => RequestType.transfer)

      @plate_a.wells.each do |well|
        Factory :library_completion, :asset => well, :target_asset => @final_tube, :submission => @submission
        Well::Link.create( :type => 'stock', :source_well => well, :target_well=> well)
      end
    end

    context "with one tube per submission" do
      should "should create transfers to the target tube" do

        @transfer = Transfer::BetweenTubesBySubmission.create!(:user=>@user,:source=>@tube_a)
        assert_equal @final_tube, @transfer.destination
        assert_equal @final_tube, @tube_a.requests.first.target_asset
      end
    end
  end
end
