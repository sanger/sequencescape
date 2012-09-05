When /^I move sample "([^\"]*)" from study "([^\"]*)" to "([^\"]*)"$/ do |sample_name, study_from_name, study_to_name|
  Then %Q{I move sample "#{sample_name}" from study "#{study_from_name}" to "#{study_to_name}", to asset group "new asset group" and submission ""}
  end

When /^I move sample "([^\"]*)" from study "([^\"]*)" to "([^\"]*)", to asset group "([^\"]*)" and submission "([^\"]*)"$/ do |sample_name, study_from_name, study_to_name, asset_group, submission_id|
  When %Q{I am on the show page for sample "#{sample_name}"}
  When %Q{I follow "Move sample to different study"}
  And %Q{I select "#{study_from_name}" from "study_id_from"}
  And %Q{I select "#{study_to_name}" from "study_id_to"}

  if asset_group.present?
    begin
  And %Q{I select "#{asset_group}" from "asset_group_id"}
    rescue Capybara::OptionNotFound => ex
      # asset group doesn't exist, create a new one then.
  And %Q{I fill in "new_assets_name" with "#{asset_group}"}
    end
  end

  And %{I select "#{submission_id}" from "submission_id"} if submission_id.present?
  Then %Q{I press "Move Sample"}
  end

 When /^I move samples between studies using the spreadsheet "([^\"]*)"$/ do |file_name|
   Given %Q{I am on the sample move using spreadsheet page}
  And %Q{I fill in "file" with "data/#{file_name}"}
  Then %Q{I press "Upload spreadsheet"}
%


 end
