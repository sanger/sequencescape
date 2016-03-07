#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011 Genome Research Ltd.
Given /^the submission with UUID "([^\"]+)" has no request types$/ do |uuid|
  resource = Uuid.with_external_id(uuid).first or raise StandardError, "Cannot find submission with UUID #{uuid.inspect}"
  resource.resource.tap do |submission|
    submission.orders.map do |order|
      request_types = nil
      order.save(:validate => false)  # This is in complete violation of the laws of nature
    end
  end
end
