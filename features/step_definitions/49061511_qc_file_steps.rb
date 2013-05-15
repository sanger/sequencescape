Given /^the plate with ID (\d+) has attatched QC data with a UUID of "(.*?)"$/ do |id, uuid|
  filename = File.expand_path(File.join(Rails.root, %w{test data example_file.txt}))
  File.open(filename) do |file|
    Plate.find(id).add_qc_file(file)
  end
  set_uuid_for(Plate.find(id).qc_files.last, uuid)
end

Then /^the content should be the Qc Data$/ do
  filename = File.expand_path(File.join(Rails.root, %w{test data example_file.txt}))
  File.open(filename) do |file|
     assert_equal(file.read, page.body)
  end
  assert_equal("attachment; filename=\"example_file.txt\"", page.driver.response_headers["Content-Disposition"])
end
