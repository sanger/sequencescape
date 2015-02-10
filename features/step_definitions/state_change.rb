#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012 Genome Research Ltd.
Given /^all the "([^"]*)" requests in the last submission have been started$/ do |request_type|
  Submission.last.requests.select{|r| r.sti_type == request_type}.map(&:start!)
end
