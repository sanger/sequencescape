# frozen_string_literal: true

Given /^sequencescape is setup for 11803383$/ do
  lane = FactoryBot.create :lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed', external_release: 1
  library_tube = FactoryBot.create :library_tube
  pipeline = Pipeline.find_by(name: 'Cluster formation PE')
  request =
    FactoryBot.create :request_with_sequencing_request_type,
                      asset: library_tube,
                      target_asset: lane,
                      request_type: pipeline.request_types.last,
                      state: 'started'

  batch = FactoryBot.create :batch, state: 'started', qc_state: 'qc_manual', pipeline: pipeline
  FactoryBot.create :batch_request, request: request, batch: batch, position: 1
end

When /^I (POST|PUT) following XML to pass QC state on the last asset:$/ do |action, xml|
  lane = Lane.last
  step "I #{action} the following XML to \"/npg_actions/assets/#{lane.id}/pass_qc_state\":", xml
end

Then /^batch state should be "([^"]*)"$/ do |state|
  batch = Batch.last
  assert_equal batch.state, state
end
