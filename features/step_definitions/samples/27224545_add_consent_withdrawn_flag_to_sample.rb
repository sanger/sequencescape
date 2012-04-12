Given /^the patient has withdrawn consent for "([^"]*)"$/ do |sample|
  Sample.find_by_name(sample).withdraw_consent
end

Given /^the study "([^"]*)" has the sample "([^"]*)" in a sample tube and asset group$/ do |study, sample|
  And %Q{the study "#{study}" has an asset group called "#{sample}_group"}
  And %Q{I have a sample called "#{sample}" with metadata}
  And %Q{the sample "#{sample}" belongs to the study "#{study}"}
  And %Q{a sample tube called "#{sample}_tube" with ID #{Asset.count+1}}
  And %Q{the sample "#{sample}" is in the sample tube "#{sample}_tube"}
  And %Q{the sample tube "#{sample}_tube" is in the asset group "#{sample}_group"}
end

