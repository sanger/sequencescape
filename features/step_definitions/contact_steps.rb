#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012 Genome Research Ltd.
# Contacts are displayed without any identifying tags
# in HTML that looks like this:-
#
#    <div class="info">
#      <h2>Owner</h2>
#      <ul>
#          <li><a href="http://www.example.com/profile/1">John Smith</a> (xyz1)</li>
#      </ul>
#      <h2>Manager</h2>
#      <ul>
#          <li><a href="http://www.example.com/profile/2">Mary Smith</a> (xyz2)</li>
#      </ul>
#      <h2>Followers</h2>
#      <ul>
#          <li><a href="http://www.example.com/profile/3">Jack Smith</a> (xyz3)</li>
#          <li><a href="http://www.example.com/profile/4">Lisa Smith</a> (xyz4)</li>
#      </ul>
#    </div>
#
# so we must use an xpath expression to recognise and validate them individually

Then /^I (should|should not) see the following contacts$/ do |assertion, table|
   table.hashes.each do |hash|
     xpath = '//div[@class="info"]/h2[text()="'+hash['role']+'" or text()="'+hash['role'].pluralize+'"]/following-sibling::ul[1]/li/a[text()="'+hash[:name]+'"]'
     if assertion == 'should'
       assert_have_xpath xpath
     else
       assert_have_no_xpath xpath
     end
   end
end

When /^I delete the attached file "([^"]+)"$/ do |filename|
  click_link("Delete #{ filename }")
end

When /^I delete the attached Listing Document for "([^"]*)"$/ do |file_name|
  step(%Q{I delete the attached file "#{ file_name }"})
end
