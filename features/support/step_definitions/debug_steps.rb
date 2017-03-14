# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2015 Genome Research Ltd.

Then /^log "([^\"]+)" for debugging$/ do |message|
  Rails.logger.debug("#{('=' * 19)} #{message} #{('=' * 19)}")
end

Then /^launch the debugger$/ do
  binding.pry
  puts
end

Then /^debug the javascript$/ do
  p page.driver.network_traffic
  page.driver.debug
end

Then /^stop$/ do
  step 'show me the page'
  step 'launch the debugger'
end
