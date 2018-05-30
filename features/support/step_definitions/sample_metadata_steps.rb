# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2015 Genome Research Ltd.

Given /^the fields of the sample_metadata for the sample called "([^"]+)" are prepopulated$/ do |name|
  sample = Sample.find_by!(name: name)
  sample.update_attributes!(sample_metadata_attributes: FactoryBot.attributes_for(:sample_metadata_for_api))
end
