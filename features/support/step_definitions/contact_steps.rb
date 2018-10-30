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

When /^I delete the attached file "([^"]+)"$/ do |filename|
  click_link("Delete #{filename}")
end
