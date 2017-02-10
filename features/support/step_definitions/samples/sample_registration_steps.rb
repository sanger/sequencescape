# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

Then /^every sample in study "([^"]*)" should be accessible via a request$/ do |study_name|
  study = Study.find_by(name: study_name)
  request_samples = study.requests.map(&:asset).map(&:sample)
  assert_equal request_samples.sort, study.samples.sort
end
