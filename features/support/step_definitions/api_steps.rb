# frozen_string_literal: true

# This may create invalid UUID external_id values but it means that we don't have to conform to the
# standard in our features.
# rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/AbcSize
def recursive_diff(h1, h2) # rubocop:todo Metrics/CyclomaticComplexity
  if h1.is_a?(Hash) && h2.is_a?(Hash)
    result = {}
    h1.each do |k, v|
      diff = recursive_diff(v, h2[k])
      result[k] = diff if diff
    end
    return result.size ? result : nil
  elsif h1.is_a?(Array) && h2.is_a?(Array)
    result = []
    h1
      .zip(h2)
      .each do |a, b|
        diff = recursive_diff(a, b)
        result << diff if diff
      end
    return result.size ? result : nil
  elsif h1 == h2
    return nil
  end
  h1
end
# rubocop:enable Metrics/AbcSize, Metrics/MethodLength, Metrics/PerceivedComplexity

def assert_hash_equal(h1, h2, *)
  d1 = recursive_diff(h1, h2)
  d2 = recursive_diff(h2, h1)
  assert_equal(d1, d2, *)
end

def walk_hash_structure(hash_data, &)
  case hash_data
  when Hash
    hash_data.each_with_object({}) do |(key, value), hash|
      hash[key] = walk_hash_structure(value, &) unless yield(key)
    end
  when Array
    hash_data.map { |entry| walk_hash_structure(entry, &) }
  else
    hash_data
  end
end

def assert_json_equal(expected, received, &)
  assert_hash_equal(
    walk_hash_structure(decode_json(expected, 'Expected'), &),
    walk_hash_structure(decode_json(received, 'Received'), &),
    'Differs when decoded'
  )
end

Given /^all HTTP requests to the API have the cookie "([^"]+)" set to "([^"]+)"$/ do |cookie, value|
  @cookies ||= {}
  @cookies[cookie] = value
end

Given /^no cookies are set for HTTP requests to the API$/ do
  @cookies = {}
end

Given /^the WTSI single sign-on service recognises "([^"]+)" as "([^"]+)"$/ do |key, login|
  User.find_or_create_by(login:).update!(api_key: key)
end

Given /^the WTSI single sign-on service does not recognise "([^"]+)"$/ do |cookie|
  User.find_by(api_key: cookie).update!(api_key: nil)
end

def api_request(action, path, body) # rubocop:todo Metrics/AbcSize
  raise StandardError, 'You must explicitly set the API version you are using' if @api_path.nil?

  @cookies ||= {}

  headers = {}
  headers['HTTP_ACCEPT'] = 'application/json'
  headers['CONTENT_TYPE'] = 'application/json' unless body.nil?
  headers['HTTP_COOKIE'] = @cookies.map { |k, v| "#{k}=#{v}" }.join(';') if @cookies.present?
  yield(headers) if block_given?
  page.driver.send(action.downcase, "#{@api_path}#{path}", body, headers)
end

Given /^I am using version "(\d+)" of the API$/ do |version|
  @api_path = "/api/#{version.to_i}"
end

Given /^I am using the latest version of the API$/ do
  step("I am using version \"#{Core::Service::API_VERSION}\" of the API")
end

When %r{^I (GET|PUT|POST|DELETE) the API path "(/[^"]*)"$} do |action, path|
  api_request(action, path, nil)
end

When %r{^I (POST|PUT) the following JSON to the API path "(/[^"]*)":$} do |action, path, serialized_json|
  api_request(action, path, serialized_json)
end

When %r{^I GET the "([^"]+)" from the API path "(/[^"]*)"$} do |content_type, path|
  api_request('GET', path, nil) { |headers| headers.merge!('HTTP_ACCEPT' => content_type) }
end

When %r{^I (POST|PUT) the following "([^"]+)" to the API path "(/[^"]*)":$} do |action, content_type, path, body|
  api_request(action, path, body) { |headers| headers.merge!('CONTENT_TYPE' => content_type) }
end

When %r{^I make an authorised (GET|DELETE) (?:(?:for|of) )?the API path "(/[^"]*)"$} do |action, path|
  api_request(action, path, nil) { |headers| headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = 'cucumber' }
end

# rubocop:todo Layout/LineLength
When %r{^I make an authorised (POST|PUT) with the following JSON to the API path "(/[^"]*)":$} do |action, path, serialized_json|
  # rubocop:enable Layout/LineLength
  api_request(action, path, serialized_json) { |headers| headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = 'cucumber' }
end

Given /^I have a "(.*?)" authorised user with the key "(.*?)"$/ do |permission, key|
  ApiApplication.new(name: 'test_api', key: key, privilege: permission, contact: 'none').save(validate: false)
end

When /^I retrieve the JSON for all (studies|samples|requests)$/ do |model|
  step("I GET the API path \"/#{model}\"")
end

When /^I retrieve the JSON for all requests related to the (sample|library) tube "([^"]+)"$/ do |tube_type, name|
  tube = "#{tube_type}_tube".classify.constantize.find_by(name:) or
    raise StandardError, "Cannot find #{tube_type} tube called #{name.inspect}"
  visit(url_for(controller: 'api/requests', action: 'index', "#{tube_type}_tube_id": tube.id, format: :json))
end

When /^I retrieve the JSON for the (sample|study) "([^"]+)"$/ do |model, name|
  object = model.classify.constantize.find_by(name:) or raise "Cannot find #{model} #{name.inspect}"
  visit(url_for(controller: "api/#{model.pluralize}", action: 'show', id: object, format: :json))
end

When /^I retrieve the JSON for the last request in the study "([^"]+)"$/ do |name|
  study = Study.find_by(name:) or raise StandardError, "Cannot find the study #{name.inspect}"
  raise StandardError, "It appears there are no requests for study #{name.inspect}" if study.requests.empty?

  visit(url_for(controller: 'api/requests', action: 'show', id: study.requests.last, format: :json))
end

Then /^show me the HTTP response body$/ do
  $stderr.puts('=' * 80)
  begin
    $stderr.send(:pp, JSON.parse(page.source))
  rescue StandardError
    $stderr.puts(page.source)
  end
  $stderr.puts('=' * 80)
end

Then /^ignoring "([^"]+)" the JSON should be:$/ do |key_list, serialised_json|
  regexp = Regexp.new(key_list)
  begin
    assert_json_equal(serialised_json, page.source) { |key| key.to_s =~ regexp }
  rescue StandardError
    puts page.source
    raise
  end
end

# rubocop:todo Metrics/PerceivedComplexity
def strip_extraneous_fields(left, right) # rubocop:todo Metrics/CyclomaticComplexity
  if left.is_a?(Hash) && right.is_a?(Hash)
    right.delete_if { |k, _| not left.key?(k) }
    left.each { |key, value| strip_extraneous_fields(value, right[key]) }
    right
  elsif left.is_a?(Array) && right.is_a?(Array)
    left.each_with_index { |value, index| strip_extraneous_fields(value, right[index]) }
    right
  else
    right
  end
end
# rubocop:enable Metrics/PerceivedComplexity

# I like to know where my JSON is wrong!
def decode_json(json, source)
  ActiveSupport::JSON.decode(json)
rescue StandardError => e
  raise StandardError, "#{source} JSON is invalid: #{json.inspect}"
end

Then /^the JSON should match the following for the specified fields:$/ do |serialised_json|
  expected = decode_json(serialised_json, 'Expected')
  received = decode_json(page.source, 'Received')
  strip_extraneous_fields(expected, received)
  assert_hash_equal(expected, received, "JSON #{page.source} differs in the specified fields")
end

Then /^the JSON "([^"]+)" should be exactly:$/ do |path, serialised_json|
  expected = decode_json(serialised_json, 'Expected')
  received = decode_json(page.source, 'Received')
  target = path.split('.').inject(received) { |json, key| json[key] }
  assert_equal(expected, target, 'JSON differs in the specified key path')
end

Then /^the JSON "([^"]+)" should not exist$/ do |path|
  received = decode_json(page.source, 'Received')
  steps = path.split('.')
  leaf = steps.pop
  target = steps.inject(received) { |json, key| json.try(:[], key) }
  assert(!target.key?(leaf), "#{path} should not exist") unless target.nil?
end

# This actually turns the JSON into the relevant objects for comparison because this is better: we cannot
# guarantee that the layouts will be identical for the feature and the server response.
Then /^the JSON should be:$/ do |serialised_json|
  assert_hash_equal(
    decode_json(serialised_json, 'Expected'),
    decode_json(page.source, 'Received'),
    'The JSON differs when decoded'
  )
end

Then 'the HTTP response should be {string}' do |status|
  match = /^(\d+).*/.match(status) or
    raise StandardError, "Status #{status.inspect} should be an HTTP status code + message"
  begin
    assert_equal(match[1].to_i, page.driver.status_code)
  rescue Minitest::Assertion => e
    step 'show me the HTTP response body'
    raise e
  end
end

Then /^the HTTP "([^"]+)" should be "([^"]+)"$/ do |header, value|
  assert_equal(value, page.driver.response_headers[header])
end

Then /^the JSON should not contain "([^"]+)" within any element of "([^"]+)"$/ do |name, path|
  json = decode_json(page.source, 'Received')
  target = path.split('.').inject(json) { |s, p| s.try(:[], p) } or
    raise StandardError, "Could not find #{path.inspect} in JSON"
  case target
  when Array
    target.each_with_index { |record, index| assert_nil(record[name], "Found #{name.inspect} in element #{index}") }
  when Hash
    assert_nil(target[name], "Found #{name.inspect} in element #{target}")
  end
end

##############################################################################
# TODO: These should be elsewhere!
##############################################################################
# deprecated
Given /^the sample named "([^"]+)" exists with ID (\d+)$/ do |name, id|
  step("a sample called \"#{name}\" with ID #{id}")
end

# deprecated
Given /^(\d+) samples exist with the core name "([^"]+)" and IDs starting at (\d+)$/ do |count, name, id|
  step("#{count} samples exist with names based on \"#{name}\" and IDs starting at #{id}")
end

# rubocop:todo Layout/LineLength
Given /^the (library tube|plate) "([^"]+)" is a child of the (sample tube|plate) "([^"]+)"$/ do |child_model, child_name, parent_model, parent_name|
  # rubocop:enable Layout/LineLength
  parent = parent_model.gsub(/\s+/, '_').classify.constantize.find_by(name: parent_name) or
    raise StandardError, "Cannot find the #{parent_model} #{parent_name.inspect}"
  child = child_model.gsub(/\s+/, '_').classify.constantize.find_by(name: child_name) or
    raise StandardError, "Cannot find the #{child_model} #{child_name.inspect}"
  parent.children << child
  if [parent, child].all?(Receptacle)
    child.aliquots = []
    FactoryBot.create(:transfer_request, asset: parent, target_asset: child)
    child.save!
  end
end

Given /^the well "([^"]+)" is a child of the well "([^"]+)"$/ do |child_name, parent_name|
  parent = Uuid.find_by(external_id: parent_name).resource or raise StandardError, "Cannot find #{parent_name.inspect}"
  child = Uuid.find_by(external_id: child_name).resource or raise StandardError, "Cannot find #{child_name.inspect}"
  parent.children << child
  child.aliquots.clear
  FactoryBot.create(:transfer_request, asset: parent, target_asset: child)
  child.save!
end

Given /^the sample "([^"]+)" is in (\d+) sample tubes? with sequential IDs starting at (\d+)$/ do |name, count, base_id|
  sample = Sample.find_by(name:) or raise StandardError, "Cannot find the sample #{name.inspect}"
  (1..count.to_i).each do |index|
    FactoryBot
      .create(:empty_sample_tube, name: "#{name} sample tube #{index}", id: (base_id.to_i + index - 1))
      .tap { |sample_tube| sample_tube.aliquots.create!(sample:) }
  end
end

Given /^the pathogen project called "([^"]*)" exists$/ do |project_name|
  project = FactoryBot.create :project, name: project_name, approved: true, state: 'active'
  project.update!(
    project_metadata_attributes: {
      project_manager: ProjectManager.find_by(name: 'Unallocated'),
      project_cost_code: 'ABC',
      funding_comments: 'External funding',
      collaborators: 'No collaborators',
      external_funding_source: 'EU',
      budget_division: BudgetDivision.find_by(name: 'Pathogen (including malaria)'),
      sequencing_budget_cost_centre: 'Sanger',
      project_funding_model: 'Internal'
    }
  )
end

Given /^project "([^"]*)" has an owner called "([^"]*)"$/ do |project_name, login_name|
  project = Project.find_by(name: project_name)
  user =
    FactoryBot.create :user, login: login_name, first_name: 'John', last_name: 'Doe', email: "#{login_name}@example.com"
  user.grant_owner(project)
end

Given /^the sanger sample id for sample "([^"]*)" is "([^"]*)"$/ do |uuid_value, sanger_sample_id|
  sample = Sample.find(Uuid.find_id(uuid_value))
  sample.sanger_sample_id = sanger_sample_id
  sample.save!
end

Given /^the infinium barcode for plate "([^"]*)" is "([^"]*)"$/ do |plate_name, infinium_barcode|
  plate = Plate.find_by(name: plate_name)
  plate.infinium_barcode = infinium_barcode
  plate.save!
end

Given /^the number of results returned by the API per page is (\d+)$/ do |count|
  Core::Endpoint::BasicHandler::Paged.results_per_page = count.to_i
end

Given /^the "([^"]+)" action on samples requires authorisation$/ do |action|
  Core::Abilities::Application.unregistered { cannot(action.to_sym, TestSampleEndpoint::Model) }
  Core::Abilities::Application.full { can(action.to_sym, TestSampleEndpoint::Model) }
end

Given /^the "([^"]+)" action on a sample requires authorisation$/ do |action|
  Core::Abilities::Application.unregistered { cannot(action.to_sym, TestSampleEndpoint::Instance) }
  Core::Abilities::Application.full { can(action.to_sym, TestSampleEndpoint::Instance) }
end

Given /^the "(.*?)" action on samples requires tag_plates authorisation$/ do |action|
  Core::Abilities::Application.unregistered { cannot(action.to_sym, TestSampleEndpoint::Model) }
  Core::Abilities::Application.tag_plates { can(action.to_sym, TestSampleEndpoint::Model) }
end
