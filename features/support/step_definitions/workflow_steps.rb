# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

Then /^the fields listed below should be displayed:$/ do |table|
  table.hashes.each do |details|
    assert(page.find_field(details['field']))
  end
end
