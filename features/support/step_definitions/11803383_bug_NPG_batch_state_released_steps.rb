# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2014,2015 Genome Research Ltd.

Given /^sequencescape is setup for 11803383$/ do
 lane = FactoryGirl.create :lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed', external_release: 1
 library_tube = FactoryGirl.create :library_tube
 pipeline = Pipeline.find_by(name: 'Cluster formation PE')
 request = FactoryGirl.create :request_with_sequencing_request_type, asset: library_tube, target_asset: lane, request_type: pipeline.request_types.last, state: 'started'

 batch = FactoryGirl.create :batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline
 FactoryGirl.create :batch_request, request: request, batch: batch, position: 1
end

Then /^batch state should be "([^"]*)"$/ do |state|
  batch = Batch.last
  assert_equal batch.state, state
end
