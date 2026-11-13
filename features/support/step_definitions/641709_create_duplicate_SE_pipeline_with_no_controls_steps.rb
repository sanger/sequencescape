# frozen_string_literal: true

Given /^Pipeline "([^"]*)" and a setup for 641709$/ do |name|
  pipeline = Pipeline.find_by(name:) or raise StandardError, "Cannot find pipeline '#{name}'"
  pipeline.workflow.item_limit.times { step("I have a request for \"#{name}\"") }
end

When /^I select eight requests$/ do
  Request
    .limit(8)
    .order(id: :desc)
    .each { |request| step("I check \"Select #{request.asset.human_barcode} for batch\"") }
end
