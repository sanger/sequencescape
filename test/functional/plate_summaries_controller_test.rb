#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2016 Genome Research Ltd.
require "test_helper"
require 'projects_controller'


class PlateSummariesControllerTest < ActionController::TestCase
  context "PlateSummariesController" do
    setup do
      @controller = PlateSummariesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = create :user
    end

    context "with some plates" do
      setup do
        @source_plate_a = create :source_plate
        @source_plate_b = create :source_plate
        @child_plate_a  = create :child_plate, :parent => @source_plate_a
        @child_plate_b  = create :child_plate, :parent => @source_plate_b
      end
    end
  end
end
