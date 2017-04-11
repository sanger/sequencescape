# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

Given /^for asset "([^\"]+)" a qc state "([^\"]+)"$/ do |asset_name, qc_state|
  asset = Asset.find_by(name: asset_name) or raise StandardError, "Cannot find asset #{asset_name. inspect}"
  asset.qc_state = qc_state
  asset.save
end
