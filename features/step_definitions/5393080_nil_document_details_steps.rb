#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
Then /^I should not find any nil documents$/ do
  documents = Document.all(:conditions => 'filename IS NULL')
  assert(documents.empty?, "Found nil documents: #{documents.inspect}")
end
