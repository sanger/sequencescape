# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^Pipeline "([^"]*)" and a setup for 641709$/ do |name|
 pipeline = Pipeline.find_by(name: name) or raise StandardError, "Cannot find pipeline '#{name}'"
 pipeline.workflow.item_limit.times do
   step(%Q{I have a request for "#{name}"})
 end
end

When /^I select eight requests$/ do
  Request.limit(8).order(id: :desc).each do |request|
    step(%Q{I check "Select #{request.asset.sti_type} #{request.asset.barcode} for batch"})
  end
end
