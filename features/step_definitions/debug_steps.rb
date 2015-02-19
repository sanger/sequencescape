#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012 Genome Research Ltd.
Then /^log "([^\"]+)" for debugging$/ do |message|
  Rails.logger.debug("#{('=' * 19)} #{message} #{('=' * 19)}")
end

Then /^launch the debugger$/ do
  debugger
  puts
end

Then /^stop$/ do
  step %q{show me the page}
  step %q{launch the debugger}
end
