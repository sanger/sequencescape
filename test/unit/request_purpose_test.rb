#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
require 'test_helper'

class RequestPurposeTest < ActiveSupport::TestCase
  context "RequestPurpose" do
    should_have_many :requests, :request_types
    should_validate_presence_of :key
  end
end
