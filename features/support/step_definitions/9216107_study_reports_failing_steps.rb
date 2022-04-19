# frozen_string_literal: true

Given /^each well in "([^"]*)" has a child sample tube$/ do |study_name|
  study = Study.find_by(name: study_name)
  Well.find_each { |well| well.children << FactoryBot.create(:sample_tube) }
  RequestFactory.create_assets_requests(SampleTube.all, study)
end
