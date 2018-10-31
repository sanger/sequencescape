Given /^study "([^"]+)" has a registered sample "([^"]+)" with no submissions$/ do |study_name, sample_name|
  study  = Study.find_by!(name: study_name)
  sample = study.samples.create!(name: sample_name)
end
