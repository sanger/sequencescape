#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2015 Genome Research Ltd.
FactoryGirl.define do
  sequence :asset_group_name do |n|
    "Asset_Group #{n}"
  end

  sequence :asset_name do |n|
    "Asset #{n}"
  end

  sequence :barcode do |n|
    "DN#{n}"
  end

  sequence :barcode_number do |n|
    "#{n}"
  end

  sequence :budget_division_name do |n|
    "Budget Division#{n}"
  end

  sequence :faculty_sponsor_name do |n|
    "Faculty Sponsor #{n}"
  end

  sequence :item_name do |n|
    "Item #{n}"
  end

  sequence :item_version do |n|
    n
  end

  sequence :keys do |n|
    "Key #{n}"
  end

  sequence :lab_workflow_name do |n|
    "Lab Workflow #{n}"
  end

  sequence :library_type_id do |n|
    n
  end

  sequence :purpose_name do |n|
    "Purpose #{n}"
  end

  sequence :product_catalogue_name do |n|
    "ProductCatalogue#{n}"
  end

  sequence :product_name do |n|
    "Product#{n}"
  end

  sequence :program_name do |n|
    "Program#{n}"
  end

  sequence :project_name do |n|
    "Project #{n}"
  end

  sequence :request_type_id do |n|
    n
  end

  sequence :request_type_key do |n|
    "request_type_#{n}"
  end

  sequence :request_type_name do |n|
    "Request Type #{n}"
  end


  sequence :sample_name do |n|
    "Sample#{n}"
  end

  sequence :study_name do |n|
    "Study #{n}"
  end

  sequence :submission_template_name do |n|
    "Submission Template #{n}"
  end

  sequence :pipeline_name do |n|
    "Lab Pipeline #{n}"
  end
end
