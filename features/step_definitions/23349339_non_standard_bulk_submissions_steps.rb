When /^I upload a file with an empty column$/ do
  upload_submission_spreadsheet("with_empty_column")
end

When /^I upload a file with a headerless columnn$/ do
  upload_submission_spreadsheet("with_headerless_column")
end

When /^I upload a file with a header at an unexpected location$/ do
  upload_submission_spreadsheet("with_moved_header")
end