Given /^I release the last completed batch$/ do
  batch =Batch.find(:last, :conditions => {:state => "Completed"})
  visit release_batch_path(batch)
end

Given /^I finish the last started batch$/ do
  batch =Batch.find(:last, :conditions => {:state => "Started"})
  visit finish_batch_path(batch)
end

When /^I get the XML for the last batch$/ do ||
  batch = Batch.last
  visit(batch_path(batch, :format => :xml))
end

Given /^the last batch is for the "([^\"]+)" pipeline$/ do |name|
  batch    = Batch.last or raise StandardError, 'There appear to be no batches'
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Unable to find the pipeline #{name}"
  pipeline.batches << batch
end

Given /^the last batch has (\d+) requests?$/ do |count|
  batch          = Batch.last or raise StandardError, 'There appear to be no batches'
  batch.requests = (1..count.to_i).map { |_| Factory(:request_suitable_for_starting, :request_type => batch.pipeline.request_type) }
end

Given /^"([^\"]+)" is the owner of batch with ID (\d+)$/ do |login, id|
  user = User.find_by_login(login) or raise StandardError, "Cannot find user login #{login.inspect}"
  Batch.find(id).update_attributes!(:user => user)
end

Then /^all of the downstream requests from the "([^\"]+)" pipeline of the request with UUID "([^\"]+)" should be "([^\"]+)"$/ do |name, uuid, state|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  uuid     = Uuid.with_external_id(uuid).first or raise StandardError, "Cannot find UUID #{uuid.inspect}"
  requests = uuid.resource.next_requests(pipeline) { |request| true }
  raise StandardError, "There are no downstream requests of #{uuid.inspect} (#{uuid.resource.inspect})" if requests.empty?
  assert(requests.all?(&:"#{state}?"), "Some of the requests are not #{state}")
end

Then /^(\d+) of the downstream requests from the "([^\"]+)" pipeline of the request with UUID "([^\"]+)" should be "([^\"]+)"$/ do |count, name, uuid, state|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  uuid     = Uuid.with_external_id(uuid).first or raise StandardError, "Cannot find UUID #{uuid.inspect}"
  requests = uuid.resource.next_requests(pipeline) { |request| true }
  raise StandardError, "There are no downstream requests of #{uuid.inspect} (#{uuid.resource.inspect})" if requests.empty?

  assert_equal(count.to_i, requests.select(&:"#{state}?").length, "Some of the requests are not #{state}")
end

Given /^all requests for the "([^\"]+)" pipeline are in a batch$/ do |name|
  pipeline = Pipeline.find_by_name(name) or raise StandardError, "Cannot find pipeline #{name.inspect}"
  requests = pipeline.request_type.requests.all
  raise StandardError, "There appear to be no #{pipeline.request_type.name.inspect} requests" if requests.empty?
  pipeline.batches.create!(:requests => requests)
end
