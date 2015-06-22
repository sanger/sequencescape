#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
Then /^the events table should be:$/ do |expected_results_table|
  expected_results_table.diff!(table(fetch_table('table#events')))
end
