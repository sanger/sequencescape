# This may create invalid UUID external_id values but it means that we don't have to conform to the 
# standard in our features.
def recursive_diff(h1, h2)
  if h1.is_a?(Hash) && h2.is_a?(Hash)
    result = {}
    h1.each do |k,v|
      diff = recursive_diff(v, h2[k])
      result[k] = diff if diff
    end
    return result.size ? result : nil
  elsif h1.is_a?(Array) and h2.is_a?(Array)
    result = []
    h1.zip(h2).each do |a, b|
      diff = recursive_diff(a, b)
      result << diff if diff
    end
    return result.size ? result : nil
  elsif h1 == h2
    return nil
  end
  return h1
end

def assert_hash_equal(h1, h2, *args)
  d1 = recursive_diff(h1, h2)
  d2 = recursive_diff(h2, h1)
  assert_equal(d1,d2, *args)
end

#def assert_hash_equal(*args) assert_equal(*args) end

def walk_hash_structure(hash_data, &block)
  if hash_data.is_a?(Hash)
    hash_data.inject({}) do |hash,(key,value)|
      hash[key] = walk_hash_structure(value, &block) unless block.call(key)
      hash
    end
  elsif hash_data.is_a?(Array)
    hash_data.map { |entry| walk_hash_structure(entry, &block) }
  else
    hash_data
  end
end

def assert_json_equal(expected, received, &block)
  assert_hash_equal(
    walk_hash_structure(decode_json(expected, 'Expected'), &block),
    walk_hash_structure(decode_json(received, 'Received'), &block),
    'Differs when decoded'
  )
end

Given /^all HTTP requests to the API have the cookie "([^\"]+)" set to "([^\"]+)"$/ do |cookie,value|
  @cookies ||= {}
  @cookies[cookie] = value
end

Given /^no cookies are set for HTTP requests to the API$/ do
  @cookies = {}
end

Given /^the WTSI single sign-on service recognises "([^\"]+)" as "([^\"]+)"$/ do |cookie, login|
  FakeSingleSignOnService.instance.map_cookie_to_login(cookie, login)
end

Given /^the WTSI single sign-on service does not recognise "([^\"]+)"$/ do |cookie|
  FakeSingleSignOnService.instance.unmap_cookie(cookie)
end

def api_request(action, path, body)
  raise StandardError, "You must explicitly set the API version you are using" if @api_path.nil?
  @cookies  ||= {}

  headers = { }
  headers.merge!('HTTP_ACCEPT' => 'application/json')
  headers.merge!('CONTENT_TYPE' => 'application/json') unless body.nil?
  headers.merge!('HTTP_COOKIE' => @cookies.map { |k,v| "#{k}=#{v}" }.join(';')) unless @cookies.blank?
  yield(headers) if block_given?

  page.driver.send(action.downcase, "#{@api_path}#{path}", body, headers)
end
def json_api_request(*args, &block)
  api_request(*args, &block)
end

Given /^I am using version "(\d+)" of the API$/ do |version|
  @api_path = "/api/#{version.to_i}"
end

Given /^I am using the latest version of the API$/ do 
  Given %Q{I am using version "#{::Core::Service::API_VERSION}" of the API}
end

Given /^I am using version "([^\"]+)" of a legacy API$/ do |version|
  @api_path = version
end

When /^I (GET|PUT|POST|DELETE) the API path "(\/[^\"]*)"$/ do |action, path|
  json_api_request(action, path, nil)
end

When /^I (POST|PUT) the following JSON to the API path "(\/[^\"]*)":$/ do |action, path, serialized_json|
  json_api_request(action, path, serialized_json)
end

When /^I GET the "([^\"]+)" from the API path "(\/[^\"]*)"$/ do |content_type, path|
  api_request('GET', path, nil) do |headers|
    headers.merge!('HTTP_ACCEPT' => content_type)
  end
end

When /^I (POST|PUT) the following "([^\"]+)" to the API path "(\/[^\"]*)":$/ do |action, content_type, path, body|
  api_request(action, path, body) do |headers|
    headers.merge!('CONTENT_TYPE' => content_type)
  end
end

When /^I make an authorised (GET|PUT|POST|DELETE) the API path "(\/[^\"]*)"$/ do |action, path|
  api_request(action, path, nil) do |headers|
    headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = 'cucumber'
  end
end

When /^I make an authorised (POST|PUT) with the following JSON to the API path "(\/[^\"]*)":$/ do |action, path, serialized_json|
  api_request(action, path, serialized_json) do |headers|
    headers['HTTP_X_SEQUENCESCAPE_CLIENT_ID'] = 'cucumber'
  end
end

When /^I retrieve the JSON for all (studies|samples|requests)$/ do |model|
  When %Q{I GET the API path "/#{model}"}
end

When /^I retrieve the JSON for all requests related to the (sample|library) tube "([^\"]+)"$/ do |tube_type, name|
  tube = "#{ tube_type }_tube".classify.constantize.find_by_name(name) or raise StandardError, "Cannot find #{ tube_type } tube called #{ name.inspect }"
  visit(url_for(:controller => "api/requests", :action => 'index', :"#{ tube_type }_tube_id" => tube.id, :format => :json))
end

When /^I retrieve the JSON for the (sample|study) "([^\"]+)"$/ do |model,name|
  object = model.classify.constantize.find_by_name(name) or raise "Cannot find #{ model } #{ name.inspect }"
  visit(url_for(:controller => "api/#{model.pluralize}", :action => 'show', :id => object, :format => :json))
end

When /^I retrieve the JSON for the last request in the study "([^\"]+)"$/ do |name|
  study        = Study.find_by_name(name) or raise StandardError, "Cannot find the study #{ name.inspect }"
  raise StandardError, "It appears there are no requests for study #{ name.inspect }" if study.requests.empty?
  visit(url_for(:controller => "api/requests", :action => 'show', :id => study.requests.last, :format => :json))
end

Then /^show me the HTTP response body$/ do
  $stderr.puts('=' * 80)
  $stderr.puts page.body
  $stderr.puts('=' * 80)
end

Then /^ignoring "([^\"]+)" the JSON should be:$/ do |key_list, serialised_json|
  regexp = Regexp.new(key_list)
  assert_json_equal(serialised_json, page.body) do |key|
    key.to_s =~ regexp
  end
end

Then /^ignoring everything but "([^\"]+)" the JSON should be:$/ do |key_list, serialised_json|
  keys = key_list.split('|')
  assert_json_equal(serialised_json, page.body) do |key|
    not keys.include?(key.to_s)
  end
end

def strip_extraneous_fields(left, right)
  if left.is_a?(Hash) and right.is_a?(Hash)
    right.delete_if { |k,_| not left.keys.include?(k) }
    left.each { |key,value| strip_extraneous_fields(value, right[key]) }
    right
  elsif left.is_a?(Array) and right.is_a?(Array)
    left.each_with_index do |value,index|
      strip_extraneous_fields(value, right[index])
    end
    right
  else
    right
  end
end

# I like to know where my JSON is wrong!
def decode_json(json, source)
  ActiveSupport::JSON.decode(json)
rescue StandardError => exception
  raise exception
  raise StandardError, "#{source} JSON is invalid: #{json.inspect}"
end

Then /^the JSON should match the following for the specified fields:$/ do |serialised_json|
  expected = decode_json(serialised_json, 'Expected')
  received = decode_json(page.body, 'Received')
  strip_extraneous_fields(expected, received)
  assert_hash_equal(expected, received, 'JSON differs in the specified fields')
end

Then /^the JSON "([^\"]+)" should be exactly:$/ do |path, serialised_json|
  expected = decode_json(serialised_json, 'Expected')
  received = decode_json(page.body, 'Received')
  target   = path.split('.').inject(received) { |json,key| json[key] }
  assert_equal(expected, target, 'JSON differs in the specified key path')
end

Then /^the JSON "([^\"]+)" should not exist$/ do |path|
  received = decode_json(page.body, 'Received')
  steps    = path.split('.')
  leaf     = steps.pop
  target   = steps.inject(received) { |json,key| json.try(:[], key) }
  assert(!target.key?(leaf), "#{path} should not exist") unless target.nil?
end

# This actually turns the JSON into the relevant objects for comparison because this is better: we cannot
# guarantee that the layouts will be identical for the feature and the server response.
Then /^the JSON should be:$/ do |serialised_json|
  assert_hash_equal(
    decode_json(serialised_json, 'Expected'),
    decode_json(page.body, 'Received'),
    'The JSON differs when decoded'
  )
end

Then /^the HTTP response should be "([^\"]+)"$/ do |status|
  match = /^(\d+).*/.match(status) or raise StandardError, "Status #{status.inspect} should be an HTTP status code + message"
  assert_equal(match[1].to_i, page.driver.status_code)
end

Then /^the HTTP "([^\"]+)" should be "([^\"]+)"$/ do |header,value|
  assert_equal(value, page.driver.response_headers[header])
end

Then /^the HTTP response body should be empty$/ do
  assert(page.body.blank?, 'The response body is not blank')
end

Then /^the JSON should be an empty array$/ do 
  assert_hash_equal([], decode_json(page.body, 'Received'), 'The JSON is not an empty array')
end

Then /^the JSON should not contain "([^\"]+)" within any element of "([^\"]+)"$/ do |name, path|
  json   = decode_json(page.body, 'Received')
  target = path.split('.').inject(json) { |s,p| s.try(:[], p) } or raise StandardError, "Could not find #{path.inspect} in JSON"
  target.each_with_index do |record, index|
    assert_nil(record[name], "Found #{name.inspect} in element #{index}")
  end
end

##############################################################################
# TODO: These should be elsewhere!
##############################################################################
# deprecated
Given /^the sample named "([^\"]+)" exists with ID (\d+)$/ do |name, id|
  Given %Q{a sample called "#{name}" with ID #{id}}
end

# deprecated
Given /^(\d+) samples exist with the core name "([^\"]+)" and IDs starting at (\d+)$/ do |count,name,id|
  Given %Q{#{count} samples exist with names based on "#{name}" and IDs starting at #{id}}
end

Given /^the (well|library tube|plate) "([^\"]+)" is a child of the (well|sample tube|plate) "([^\"]+)"$/ do |child_model, child_name, parent_model, parent_name|
  parent = parent_model.gsub(/\s+/, '_').classify.constantize.find_by_name(parent_name) or raise StandardError, "Cannot find the #{parent_model} #{parent_name.inspect}"
  child  = child_model.gsub(/\s+/, '_').classify.constantize.find_by_name(child_name) or raise StandardError, "Cannot find the #{child_model} #{child_name.inspect}"
  parent.children << child
end

Given /^the sample "([^\"]+)" is in (\d+) sample tubes? with sequential IDs starting at (\d+)$/ do |name, count, base_id|
  sample = Sample.find_by_name(name) or raise StandardError, "Cannot find the sample #{name.inspect}"
  (1..count.to_i).each do |index|
    Factory(:sample_tube, :name => "#{name} sample tube #{index}", :material => sample, :id => (base_id.to_i + index - 1))
  end
end

Given /^the pathogen project called "([^"]*)" exists$/ do |project_name|
  project = Factory :project, :name => project_name, :approved => true, :state => "active"
  project.update_attributes!(:project_metadata_attributes => {
    :project_manager => ProjectManager.find_by_name('Unallocated'),
    :project_cost_code => "ABC", 
    :funding_comments => "External funding",
    :collaborators  => "No collaborators",
    :external_funding_source  => "EU",
    :budget_division  => BudgetDivision.find_by_name('Pathogen (including malaria)'),
    :sequencing_budget_cost_centre  => "Sanger",
    :project_funding_model => "Internal"
  })
end

Given /^project "([^"]*)" has an owner called "([^"]*)"$/ do |project_name, login_name|
  project = Project.find_by_name(project_name)
  user = Factory :user, :login => login_name,  :first_name => "John", :last_name => "Doe", :email => "#{login_name}@example.com"
  user.is_owner_of(project)
end

Given /^lane "([^"]*)" has qc_state "([^"]*)"$/ do |lane_uuid, state|
  lane = Lane.find(Uuid.find_id(lane_uuid))
  lane.qc_state = state
  lane.save!
end

Given /^the sanger sample id for sample "([^"]*)" is "([^"]*)"$/ do |uuid_value, sanger_sample_id|
  sample = Sample.find(Uuid.find_id(uuid_value))
  sample.sanger_sample_id = sanger_sample_id
  sample.save!
end

Given /^the infinium barcode for plate "([^"]*)" is "([^"]*)"$/ do |plate_name, infinium_barcode|
  plate = Plate.find_by_name(plate_name)
  plate.plate_metadata.update_attributes!(:infinium_barcode => infinium_barcode)
end

Given /^no (submission template|plate purpose|request type)s exist$/ do |model|
  model.gsub(/\s+/, '_').camelize.constantize.destroy_all
end

Given /^the number of results returned by the API per page is (\d+)$/ do |count|
  ::Core::Endpoint::BasicHandler::Paged.results_per_page = count.to_i
end

Given /^the "([^\"]+)" action on samples requires authorisation$/ do |action|
  ::TestSampleEndpoint.model_handler.action_requires_authorisation(action.to_sym)
end

Given /^the "([^\"]+)" action on a sample requires authorisation$/ do |action|
  ::TestSampleEndpoint.instance_handler.action_requires_authorisation(action.to_sym)
end

Given /^tube "([^"]*)" is scanned in$/ do |asset_name|
  asset = Asset.find_by_name(asset_name)
  asset.events.create_scanned_into_lab!(Location.first)
end
