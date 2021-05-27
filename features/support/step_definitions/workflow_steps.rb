# frozen_string_literal: true

Then /^the fields listed below should be displayed:$/ do |table|
  table.hashes.each { |details| assert(page.find_field(details['field'])) }
end
