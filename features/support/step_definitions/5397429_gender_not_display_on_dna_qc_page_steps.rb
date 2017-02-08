# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

When /^I upload "([^\"]+)" as a sample manifest for study "([^\"]+)"$/ do |filename, name|
  step('a supplier called "Test supplier name" exists')
  step('the "96 Well Plate" barcode printer "xyz" exists')
  step('the plate barcode webservice returns "1234567"')

  # Upload the samples
  step(%Q{I am visiting study "#{name}" homepage})
  step('I follow "Sample Manifests"')
  step(%Q{a manifest has been created for "#{name}"})
  step(%Q{I attach the relative file "#{filename}" to "File to upload"})
  step('I press "Upload manifest"')

  step('the manifests are successfully processed')
end

Given /^the manifests are successfully processed$/ do
  step('1 pending delayed jobs are processed')

  manifests = SampleManifest.all
  assert(manifests.all? { |m| m.last_errors.blank? }, "There are sample manifests with errors: #{manifests.inspect}")
end

When /^I create a submission with plate "([^\"]+)" for study "([^\"]+)" under project "([^\"]+)"$/ do |plate, study, project|
  step(%Q{I am on the show page for study "#{study}"})
  step('I follow "Submit plates"')
  step(%Q{I select "#{project}" from "Project"})
  step(%Q{I fill in "Barcodes" with "#{plate}"})
  step('I press "Submit"')

  step('1 pending delayed jobs are processed')
end

When /^I start request (\d+) in the "([^\"]+)" pipeline$/ do |index, pipeline|
  step('I follow "Pipelines"')
  step(%Q{I follow "#{pipeline}"})
  step(%Q{I check "Include request #{index}"})
  step('I select "Create Batch" from the first "Action to perform"')
  step('I press the first "Submit"')
  step('I follow "QC result"')
end
