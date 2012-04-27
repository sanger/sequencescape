When /^I attach the example spreadsheet to "([^\"]+)"$/ do |field|
  filename = File.expand_path(File.join(Rails.root, %w{public data short_read_sequencing sample_spreadsheet.xls}))
  step %Q{I attach the file "#{filename}" to "#{field}"}
end
