#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2015 Genome Research Ltd.

Factory.sequence :asset_group_name do |n|
  "Asset_Group #{n}"
end

Factory.sequence :asset_name do |n|
  "Asset #{n}"
end

Factory.sequence :barcode do |n|
  "DN#{n}"
end

Factory.sequence :barcode_number do |n|
  "#{n}"
end

Factory.sequence :budget_division_name do |n|
  "Budget Division#{n}"
end

Factory.sequence :faculty_sponsor_name do |n|
  "Faculty Sponsor #{n}"
end

Factory.sequence :item_name do |n|
  "Item #{n}"
end

Factory.sequence :item_version do |n|
  n
end

Factory.sequence :keys do |n|
  "Key #{n}"
end

Factory.sequence :library_type_id do |n|
  n
end

Factory.sequence :purpose_name do |n|
  "Purpose #{n}"
end

Factory.sequence :product_catalogue_name do |n|
  "ProductCatalogue#{n}"
end

Factory.sequence :product_name do |n|
  "Product#{n}"
end

Factory.sequence :project_name do |n|
  "Project #{n}"
end

Factory.sequence :request_type_id do |n|
  n
end

Factory.sequence :sample_name do |n|
  "Sample#{n}"
end

Factory.sequence :study_name do |n|
  "Study #{n}"
end

Factory.sequence :lab_workflow_name do |n|
  "Lab Workflow #{n}"
end

Factory.sequence :pipeline_name do |n|
  "Lab Pipeline #{n}"
end
