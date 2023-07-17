# frozen_string_literal: true

Given /^the plate with ID (\d+) has attached QC data with a UUID of "(.*?)"$/ do |id, uuid|
  filename = File.expand_path(File.join(Rails.root, %w[test data example_file.txt])) # rubocop:disable Rails/RootPathnameMethods
  File.open(filename) { |file| Plate.find(id).add_qc_file(file) }
  set_uuid_for(Plate.find(id).qc_files.last, uuid)
end

Then /^the content should be the Qc Data$/ do
  filename = File.expand_path(File.join(Rails.root, %w[test data example_file.txt])) # rubocop:disable Rails/RootPathnameMethods
  File.open(filename) { |file| assert_equal(file.read, page.source) }
  assert_equal('attachment; filename="example_file.txt"', page.driver.response_headers['Content-Disposition'])
end

When /^I make an authorised POST with the QC file to the API path "(.*?)"$/ do |path|
  filename = File.expand_path(File.join(Rails.root, %w[test data example_file.txt])) # rubocop:disable Rails/RootPathnameMethods
  File.open(filename) do |file|
    file_send(path, file) { |headers| headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = 'cucumber' }
  end
end

Then /^the plate with ID (\d+) should have attached QC data$/ do |id|
  filename = File.expand_path(File.join(Rails.root, %w[test data example_file.txt])) # rubocop:disable Rails/RootPathnameMethods
  assert_equal(1, Plate.find(id).qc_files.count)
  new_data = Plate.find(id).qc_files.first.current_data
  File.open(filename) { |file| assert_equal(file.read, new_data) }
  assert_equal('example_file.txt', Plate.find(id).qc_files.first.filename)
end

def file_send(path, file) # rubocop:todo Metrics/AbcSize
  raise StandardError, 'You must explicitly set the API version you are using' if @api_path.nil?

  @cookies ||= {}

  headers = {}
  headers['HTTP_ACCEPT'] = 'application/json'
  headers['CONTENT_TYPE'] = 'sequencescape/qc_file'
  headers['HTTP_CONTENT_DISPOSITION'] = 'form-data; filename="example_file.txt"'
  headers['HTTP_COOKIE'] = @cookies.map { |k, v| "#{k}=#{v}" }.join(';') if @cookies.present?
  yield(headers) if block_given?
  page.driver.post("#{@api_path}#{path}", file.read, headers)
end
