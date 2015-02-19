#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
When /^I retrieve the XML for the asset "([^\"]+)"$/ do |id|
  asset = Asset.find(id)
  page.driver.get(asset_path(:id => asset, :format => :xml), 'Accepts' => 'application/xml')
end
