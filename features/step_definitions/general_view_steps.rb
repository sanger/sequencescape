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

Then /^I should see a dropdown labeled "([^\"]+)" with:$/ do |label_text,select_options|
  options = select_options.raw.inject([]) { |options,option| options << option }
  page.has_select?(label_text, options)
end

Then /^I should see a button marked "([^\"]+)"$/ do |button_text|
  page.has_xpath? "//input[type=submit][value='#{button_text}']"
end

Then /^I should see a field marked "([^\"]+)"$/ do |field_label_text|
  assert find_field(field_label_text)
end

When /^I fill in "([^\"]+)" with the human barcode "(..)(.+)."$/ do |field,prefix,number|
  step %Q{I fill in "#{ field }" with "#{ Barcode.calculate_barcode(prefix, number.to_i) }"}
end
