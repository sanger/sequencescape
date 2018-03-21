# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

Given /^an asset with name "([^"]*)", EAN barcode "([^"]*)"$/ do |name_asset, barcode|
  asset = FactoryGirl.create :asset, name: name_asset, barcode: barcode
end
