#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
Given /^study "([^"]+)" has a registered sample "([^"]+)" with no submissions$/ do |study_name,sample_name|
  study  = Study.first(:conditions => { :name => study_name }) or raise "No study defined with name '#{ study_name }'"
  sample = study.samples.create!(:name => sample_name)
end
