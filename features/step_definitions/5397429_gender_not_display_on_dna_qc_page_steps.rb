#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2013 Genome Research Ltd.
When /^I upload "([^\"]+)" as a sample manifest for study "([^\"]+)"$/ do |filename, name|
  step(%Q{a supplier called "Test supplier name" exists})
  step(%Q{the "96 Well Plate" barcode printer "xyz" exists})
  step(%Q{the plate barcode webservice returns "1234567"})

  # Upload the samples
  step(%Q{I am visiting study "#{name}" homepage})
  step(%Q{I follow "Sample Manifests"})
  step(%Q{a manifest has been created for "#{name}"})
  step(%Q{I attach the relative file "#{filename}" to "File to upload"})
  step(%Q{I press "Upload manifest"})

  step(%Q{the manifests are successfully processed})
end

Given /^the manifests are successfully processed$/ do
  step(%Q{1 pending delayed jobs are processed})

  manifests = SampleManifest.all
  assert(manifests.all? { |m| m.last_errors.blank? }, "There are sample manifests with errors: #{ manifests.inspect }")
end

When /^I create a submission with plate "([^\"]+)" for study "([^\"]+)" under project "([^\"]+)"$/ do |plate, study, project|
  step(%Q{I am on the show page for study "#{study}"})
  step(%Q{I follow "Submit plates"})
  step(%Q{I select "#{project}" from "Project"})
  step(%Q{I fill in "Barcodes" with "#{plate}"})
  step(%Q{I press "Submit"})

  step(%Q{1 pending delayed jobs are processed})
end

When /^I start request (\d+) in the "([^\"]+)" pipeline$/ do |index, pipeline|
  step(%Q{I follow "Pipelines"})
  step(%Q{I follow "#{pipeline}"})
  step(%Q{I check "Include request #{index}"})
  step(%Q{I select "Create Batch" from the first "Action to perform"})
  step(%Q{I press the first "Submit"})
  step(%Q{I follow "QC result"})
end
