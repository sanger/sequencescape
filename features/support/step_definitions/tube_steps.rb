# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2015 Genome Research Ltd.

Given /^a "([^"]*)" tube called "([^"]*)" exists$/ do |tube_purpose, tube_name|
  purpose = Tube::Purpose.find_by!(name: tube_purpose)
  test = purpose.target_type.constantize.create!(
    name: tube_name,
    purpose: purpose
  )
end
