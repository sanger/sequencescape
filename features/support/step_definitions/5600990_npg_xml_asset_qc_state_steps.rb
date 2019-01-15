Given /^sequencescape is setup for 5600990$/ do
  lane = FactoryBot.create :lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed', external_release: 1
  library_tube = FactoryBot.create :empty_library_tube

  request = FactoryBot.create :request_with_sequencing_request_type, asset: library_tube, target_asset: lane, state: 'started'

  batch = FactoryBot.create :batch, state: 'started', qc_state: 'qc_manual'
  batch.pipeline.request_types << request.request_type
  FactoryBot.create :batch_request, request: request, batch: batch, position: 1
end

Given /^a second request$/ do
  lane = Lane.find_by(name: 'NPG_Action_Lane_Test')
  library_tube = FactoryBot.create :empty_library_tube
  request = FactoryBot.create :request_with_sequencing_request_type, asset: library_tube, target_asset: lane
end

Given /^a pass event for the request$/ do
  lane = Lane.find_by(name: 'NPG_Action_Lane_Test')
  request = lane.source_request
  FactoryBot.create :event, eventful: request, created_by: 'npg', family: 'pass'
end

When /^I (POST|PUT) following XML to fail QC state on the last asset:$/ do |action, xml|
  lane = Lane.last
  step %Q{I #{action} the following XML to "/npg_actions/assets/#{lane.id}/fail_qc_state":}, xml
end

When /^I (POST|PUT) following XML to pass QC state on the last asset:$/ do |action, xml|
  lane = Lane.last
  step %Q{I #{action} the following XML to "/npg_actions/assets/#{lane.id}/pass_qc_state":}, xml
end

When /^I (POST|PUT) following XML to change the QC state on the asset that does not exist:$/ do |action, xml|
  step %Q{I #{action} the following XML to "/npg_actions/assets/9999999999/fail_qc_state":}, xml
end
