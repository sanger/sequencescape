# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

Given /^I release the last completed batch$/ do
  batch = Batch.where(state: 'Completed').last
  visit release_batch_path(batch)
end

Given /^I finish the last started batch$/ do
  batch = Batch.where(state: 'Started').last
  visit finish_batch_path(batch)
end

When /^I get the XML for the last batch$/ do ||
  batch = Batch.last
  visit(batch_path(batch, format: :xml))
end

Given /^the last batch is for the "([^\"]+)" pipeline$/ do |name|
  batch    = Batch.last or raise StandardError, 'There appear to be no batches'
  pipeline = Pipeline.find_by(name: name) or raise StandardError, "Unable to find the pipeline #{name}"
  pipeline.batches << batch
end

Given /^"([^\"]+)" is the owner of batch with ID (\d+)$/ do |login, id|
  user = User.find_by(login: login) or raise StandardError, "Cannot find user login #{login.inspect}"
  Batch.find(id).update_attributes!(user: user)
end

When /^the batch is started$/ do
  Batch.last.start!(User.last)
end

Then /^the customer should accept responsibility for all requests in the last batch$/ do
  Batch.last.requests.all? { |r| r.request_metadata.customer_accepts_responsibility? }
end
