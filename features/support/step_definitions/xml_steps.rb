# frozen_string_literal: true

def sort_arrays(xml_data)
  case xml_data
  when Hash
    xml_data.transform_values { |v| sort_arrays(v) }
  when Array
    # Kind of a hack but works for the cases where Hash elements exist
    xml_data.map { |e| sort_arrays(e) }.sort_by(&:to_a)
  else
    xml_data
  end
end

def assert_xml_strings_equal(str1, str2)
  expected = sort_arrays(Hash.from_xml(str1))
  received = sort_arrays(Hash.from_xml(str2))
  assert_hash_equal(expected, received, 'XML differs when decoded')
end

Then /^ignoring "([^"]+)" the XML response should be:$/ do |key_regexp, serialized_xml|
  regexp = Regexp.new(key_regexp)
  block = ->(key) { key.to_s =~ regexp }
  assert_hash_equal(
    sort_arrays(walk_hash_structure(Hash.from_xml(serialized_xml), &block)),
    sort_arrays(walk_hash_structure(Hash.from_xml(page.source), &block)),
    'XML differs when decoded'
  )
end

Then(/^the XML response should be:/) { |serialized_xml| assert_xml_strings_equal(serialized_xml, page.source) }

Then(
  /^the value of the "([^"]+)" attribute of the XML element "([^"]+)" should be "([^"]+)"/
) do |attribute, xpath, value|
  node = page.find(:xpath, xpath.downcase)
  assert node
  assert_equal value, node[attribute.downcase]
end

Then /^the text of the XML element "([^"]+)" should be "([^"]+)"/ do |xpath, value|
  node = page.find(:xpath, xpath.downcase)
  assert node
  assert_equal value, node.text
end

# Use for individual instances E.g. the Study named "Something Or Other"
When /^I request XML for (.+)$/ do |page_name|
  page.driver.get(path_to(page_name), nil, 'HTTP_ACCEPT' => 'application/xml')
end

When %r{^I (POST|PUT) the following XML to "(/[^"]+)":$} do |action, path, xml|
  page.driver.send(
    action.downcase,
    path.to_s,
    xml,
    'CONTENT_TYPE' => 'application/xml',
    'HTTP_ACCEPT' => 'application/xml'
  )
end
