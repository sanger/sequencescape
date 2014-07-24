Then /^I should not find any nil documents$/ do
  documents = Document.all(:conditions => 'filename IS NULL')
  assert(documents.empty?, "Found nil documents: #{documents.inspect}")
end
