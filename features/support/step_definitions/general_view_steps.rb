# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

# Then /^I should see an ordered list with:$/ do |ordered_list_table|
# assert_select 'ol' do
# ordered_list_table.raw.each do |text|
# assert_select 'li', :text => /#{ text }/
# end
# end
# end

# Then /^I should see an ordered list with the last entry "([^\"]+)"$/ do |entry_text|
# assert_select 'ol li:last-child', :text => /#{ entry_text }/
# end

Then /^I should see a dropdown labeled "([^\"]+)" with:$/ do |label_text, select_options|
  options = select_options.raw.inject([]) { |options, option| options << option }
  page.has_select?(label_text, options)
end

Then /^I should see a button marked "([^\"]+)"$/ do |button_text|
  page.has_xpath? "//input[type=submit][value='#{button_text}']"
end

Then /^I should see a field marked "([^\"]+)"$/ do |field_label_text|
  assert find_field(field_label_text)
end

When /^I fill in "([^\"]+)" with the human barcode "(..)(.+)."$/ do |field, prefix, number|
  step(%Q{I fill in "#{field}" with "#{Barcode.calculate_barcode(prefix, number.to_i)}"})
end
