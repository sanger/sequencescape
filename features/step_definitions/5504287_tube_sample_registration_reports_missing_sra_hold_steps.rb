#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
When /^I attach the example spreadsheet to "([^\"]+)"$/ do |field|
  filename = File.expand_path(File.join(Rails.root, %w{public data short_read_sequencing sample_spreadsheet.xls}))
  step(%Q{I attach the file "#{filename}" to "#{field}"})
end
