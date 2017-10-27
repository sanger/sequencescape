# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class RequestTypeTest < ActiveSupport::TestCase
  context RequestType do
    should have_many :requests
    #    should_belong_to :workflow, :class_name => "Submission::Workflow"
    should validate_presence_of :order
    should validate_presence_of :request_purpose
    should validate_numericality_of :order
  end
end
