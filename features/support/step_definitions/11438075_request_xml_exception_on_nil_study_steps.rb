# frozen_string_literal: true

Given /^I have a request (\d+) with a study (\d+)$/ do |request_id, study_id|
  study = FactoryBot.create(:study, id: study_id, name: 'Study 999')
  project = FactoryBot.create(:project, id: 1)
  request_type = RequestType.find_by(key: 'library_creation')
  request = FactoryBot.create(
    :request,
    id: request_id,
    study: study, project: project, request_type: request_type,
    asset: FactoryBot.create(:sample_tube)
  )
end

Given /^I have a request (\d+) without a request type$/ do |request_id|
  study = FactoryBot.create(:study, id: 999, name: 'Study 999')
  project = FactoryBot.create(:project, id: 1)
  request = FactoryBot.create(
    :request, id: request_id,
              study: study, project: project,
              asset: FactoryBot.create(:sample_tube)
  )
  request.update!(request_type: nil)
end
