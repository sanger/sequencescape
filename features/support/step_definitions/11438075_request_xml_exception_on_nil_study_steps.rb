# frozen_string_literal: true

Given /^I have a request (\d+) with a study (\d+)$/ do |request_id, study_id|
  study = FactoryBot.create(:study, id: study_id, name: 'Study 999')
  project = FactoryBot.create(:project)
  request_type = RequestType.find_by(key: 'library_creation')
  request =
    FactoryBot.create(
      :request,
      id: request_id,
      study:,
      project:,
      request_type:,
      asset: FactoryBot.create(:sample_tube)
    )
end
