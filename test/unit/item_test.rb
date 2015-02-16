#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"

class ItemTest < ActiveSupport::TestCase
  context "An Item" do

    should_have_many :requests
    should_validate_presence_of :name

 #   should_require_unique_attributes :name, :message => "already in use"

    context "#workflow" do
      setup do
        @workflow = Factory :submission_workflow
        @item = Factory :item, :workflow => @workflow
      end

      should "return a value for workflow on an Item" do
        assert_kind_of Integer, @item.workflow_id
      end

      should "return a valid value of a workflow if exists" do
        assert_equal @workflow.id, @item.workflow_id
      end
    end
  end

end
