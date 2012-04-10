Given /^study "([^"]+)" has a registered sample "([^"]+)" with no submissions$/ do |study_name,sample_name|
  study  = Study.first(:conditions => { :name => study_name }) or raise "No study defined with name '#{ study_name }'"
  sample = study.samples.create!(:name => sample_name)
end