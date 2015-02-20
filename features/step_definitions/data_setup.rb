#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2011,2012,2014 Genome Research Ltd.
require 'import_pulled_data'
class NilClass
  def failed?
    true
  end
end
Given /^data are preloaded from "([^\"]+)" renaming:$/ do |file_name, table|
  names_map = Hash[table.rows.map { |o,n| [o,n] }]
  ImportPulledData::import_from_yaml("data/setup/#{file_name}.yml", names_map)
end
Given /^data are preloaded from "([^\"]+)"$/ do |file_name|
  step(%Q{data are preloaded from "#{file_name}" renaming:})
end
