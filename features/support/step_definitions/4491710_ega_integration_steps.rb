# frozen_string_literal: true

Given /^an accession number is required for study "([^"]*)"$/ do |study_name|
  study = Study.find_by(name: study_name) or raise StandardError, "Cannot find study #{study_name.inspect}"
  study.enforce_accessioning = true
  study.enforce_data_release = true
  study.save!
end
