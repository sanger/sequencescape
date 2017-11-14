# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015,2016 Genome Research Ltd.

require 'test_helper'

class RequestTest < ActiveSupport::TestCase
  include AASM
  context 'A Request' do
    should belong_to :user
    should belong_to :request_type
    should belong_to :item
    should have_many :events
    should validate_presence_of :request_purpose
    should_have_instance_methods :pending?, :start, :started?, :fail, :failed?, :pass, :passed?, :reset, :workflow_id
  end
end
