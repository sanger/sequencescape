# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

Given /^I have a request (\d+) with a study (\d+)$/ do |request_id, study_id|
  study = FactoryGirl.create(:study, id: study_id, name: 'Study 999')
  project = FactoryGirl.create(:project, id: 1)
  request_type = RequestType.find_by(key: 'library_creation')
  request = FactoryGirl.create(
    :request,
    id: request_id,
    study: study, project: project, request_type: request_type,
    asset: FactoryGirl.create(:sample_tube)
  )
end

Given /^I have a request (\d+) without a request type$/ do |request_id|
  study = FactoryGirl.create(:study, id: 999, name: 'Study 999')
  project = FactoryGirl.create(:project, id: 1)
  request = FactoryGirl.create(
    :request, id: request_id,
              study: study, project: project,
              asset: FactoryGirl.create(:sample_tube)
  )
  request.update_attributes!(request_type: nil)
end
