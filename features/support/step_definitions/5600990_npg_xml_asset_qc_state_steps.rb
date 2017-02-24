# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^sequencescape is setup for 5600990$/ do
 lane = FactoryGirl.create :lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed', external_release: 1
 library_tube = FactoryGirl.create :empty_library_tube

 request = FactoryGirl.create :request_with_sequencing_request_type, asset: library_tube, target_asset: lane, state: 'started'

 batch = FactoryGirl.create :batch, state: 'started', qc_state: 'qc_manual'
 FactoryGirl.create :batch_request, request: request, batch: batch, position: 1
end

Given /^a second request$/ do
 lane = Lane.find_by(name: 'NPG_Action_Lane_Test')
 library_tube = FactoryGirl.create :empty_library_tube
 request = FactoryGirl.create :request_with_sequencing_request_type, asset: library_tube, target_asset: lane
end

Given /^an event to the request$/ do
 lane = Lane.find_by(name: 'NPG_Action_Lane_Test')
 request = lane.source_request
 FactoryGirl.create :event, eventful: request, created_by: 'npg'
end

When /^I (POST|PUT) following XML to change the QC state on the last asset:$/ do |action, xml|
 lane = Lane.last
 step %Q{I #{action} the following XML to "/npg_actions/assets/#{lane.id}/fail_qc_state":}, xml
end

When /^I (POST|PUT) following XML to change in passed the QC state on the last asset:$/ do |action, xml|
 lane = Lane.last
 step %Q{I #{action} the following XML to "/npg_actions/assets/#{lane.id}/pass_qc_state":}, xml
end

When /^I (POST|PUT) following XML to change the QC state on the asset that does not exist:$/ do |action, xml|
 step %Q{I #{action} the following XML to "/npg_actions/assets/9999999999/fail_qc_state":}, xml
end
