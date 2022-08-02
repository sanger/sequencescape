# frozen_string_literal: true

FactoryBot.define do
  sequence :asset_group_name do |n|
    "Asset_Group #{n}"
  end

  sequence :asset_name do |n|
    "Asset #{n}"
  end

  sequence(:sanger_barcode) { "SQPD-#{generate(:barcode_number)}" }

  sequence(:barcode) { generate(:barcode_number).to_s }

  sequence :budget_division_name do |n|
    "Budget Division#{n}"
  end

  sequence :faculty_sponsor_name do |n|
    "Faculty Sponsor #{n}"
  end

  sequence :item_name do |n|
    "Item #{n}"
  end

  sequence :keys do |n|
    "Key #{n}"
  end

  sequence :lab_workflow_name do |n|
    "Lab Workflow #{n}"
  end

  sequence :pipeline_name do |n|
    "Lab Pipeline #{n}"
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

  sequence :study_type_name do |n|
    "Study Type #{n}"
  end

  sequence :submission_template_name do |n|
    "Submission Template #{n}"
  end

  sequence :data_release_study_type_name do |n|
    "Data release study Type #{n}"
  end

  sequence :login do |i|
    "user_abc#{i}"
  end

  sequence :tag_group_name do |i|
    "tag_group_#{i}"
  end
end
