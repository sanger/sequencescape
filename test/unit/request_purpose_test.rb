# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'test_helper'

class RequestPurposeTest < ActiveSupport::TestCase
  context 'RequestPurpose' do
    should have_many :requests
    should have_many :request_types
    should validate_presence_of :key
  end
end
