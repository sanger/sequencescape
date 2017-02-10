# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

def create_and_bind_asset_to_study(name_asset, name_study)
  asset = FactoryGirl.create :asset, name: name_asset
  study = Study.find_by(name: name_study) or raise StandardError, "Cannot find study #{name_study.inspect}"
  asset.studies << study
end

Given /^the asset "([^"]*)" to the study named "([^"]*)"$/ do |name_asset, name_study|
  create_and_bind_asset_to_study(name_asset, name_study)
end
