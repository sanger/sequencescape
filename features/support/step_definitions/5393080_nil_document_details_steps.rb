Then /^I should not find any nil documents$/ do
  documents = Document.where(filename: nil)
  assert(documents.empty?, "Found nil documents: #{documents.inspect}")
end
