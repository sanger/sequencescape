When /^I upload "([^\"]+)" as a sample manifest for study "([^\"]+)"$/ do |filename, name|
  Given %Q{a supplier called "Test supplier name" exists}
  Given %Q{the "96 Well Plate" barcode printer "xyz" exists}
  Given %Q{the plate barcode webservice returns "1234567"}

  # Upload the samples
  Given %Q{I am visiting study "#{name}" homepage}
  When %Q{I follow "Sample Manifests"}
  Given %Q{a manifest has been created for "#{name}"}
  Given %Q{I attach the relative file "#{filename}" to "File to upload"}
  Given %Q{I press "Upload manifest"}

  Given %Q{the manifests are successfully processed}
end

Given /^the manifests are successfully processed$/ do
  Given %Q{1 pending delayed jobs are processed}

  manifests = SampleManifest.all
  assert(manifests.all? { |m| m.last_errors.blank? }, "There are sample manifests with errors: #{ manifests.inspect }")
end

When /^I create a submission with plate "([^\"]+)" for study "([^\"]+)" under project "([^\"]+)"$/ do |plate, study, project|
  Given %Q{I am on the show page for study "#{study}"}
  When %Q{I follow "Submit plates"}
  When %Q{I select "#{project}" from "Project"}
  When %Q{I fill in "Barcodes" with "#{plate}"}
  When %Q{I press "Submit"}

  Given %Q{1 pending delayed jobs are processed}
end

When /^I start request (\d+) in the "([^\"]+)" pipeline$/ do |index, pipeline|
  When %Q{I follow "Pipelines"}
  When %Q{I follow "#{pipeline}"}
  When %Q{I check "Include request #{index}"}
  When %Q{I select "Create Batch" from "Action to perform"}
  When %Q{I press "Submit"}
  When %Q{I follow "Start batch"}
end
