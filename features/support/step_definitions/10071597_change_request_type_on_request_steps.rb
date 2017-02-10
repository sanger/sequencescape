# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2013,2015 Genome Research Ltd.

Given /^sequencescape is setup for 10071597$/ do
 project = FactoryGirl.create :project_with_order, name: 'Test project 10071597'
 lane = FactoryGirl.create :lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed'
 library_tube = FactoryGirl.create :empty_library_tube
 request_type = RequestType.find_by(name: 'Illumina-B Paired end sequencing')
 request = FactoryGirl.create :request, asset: library_tube, target_asset: lane, state: 'pending', project: project, request_type: request_type
 project.update_attributes!(enforce_quotas: true)
end

Given /^last request the state "([^\"]*)"$/ do |state|
 request = Request.last
 request.state = state
 request.save
end
