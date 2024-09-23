# frozen_string_literal: true

Given /^sequencescape is setup for 10071597$/ do
  project = FactoryBot.create :project_with_order, name: 'Test project 10071597'
  lane = FactoryBot.create :lane, name: 'NPG_Action_Lane_Test', qc_state: 'passed'
  library_tube = FactoryBot.create :empty_library_tube
  request_type = RequestType.find_by(name: 'Illumina-B Paired end sequencing')
  request =
    FactoryBot.create(:request,
                      asset: library_tube,
                      target_asset: lane,
                      state: 'pending',
                      project:,
                      request_type:)
  project.update!(enforce_quotas: true)
end

Given /^last request the state "([^"]*)"$/ do |state|
  request = Request.last
  request.state = state
  request.save
end
