# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2013,2015 Genome Research Ltd.

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
     assert_equal(file.read, page.source)
  end
  assert_equal('attachment; filename="example_file.txt"', page.driver.response_headers['Content-Disposition'])
end

When /^I make an authorised POST with the QC file to the API path "(.*?)"$/ do |path|
  filename = File.expand_path(File.join(Rails.root, %w{test data example_file.txt}))
  File.open(filename) do |file|
    file_send(path, file) { |headers| headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = 'cucumber' }
  end
end

Then /^the plate with ID (\d+) should have attatched QC data$/ do |id|
  filename = File.expand_path(File.join(Rails.root, %w{test data example_file.txt}))
  assert_equal(1, Plate.find(id).qc_files.count)
  new_data = Plate.find(id).qc_files.first.current_data
  File.open(filename) do |file|
    assert_equal(file.read, new_data)
  end
  assert_equal('example_file.txt', Plate.find(id).qc_files.first.filename)
end

def file_send(path, file)
  raise StandardError, 'You must explicitly set the API version you are using' if @api_path.nil?
  @cookies ||= {}

  headers = {}
  headers['HTTP_ACCEPT'] = 'application/json'
  headers['CONTENT_TYPE'] = 'sequencescape/qc_file'
  headers['HTTP_CONTENT_DISPOSITION'] = 'form-data; filename="example_file.txt"'
  headers['HTTP_COOKIE'] = @cookies.map { |k, v| "#{k}=#{v}" }.join(';') unless @cookies.blank?
  yield(headers) if block_given?
  page.driver.post("#{@api_path}#{path}", file.read, headers)
end
