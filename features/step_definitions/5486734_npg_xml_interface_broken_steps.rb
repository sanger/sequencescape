When /^I retrieve the XML for the asset "([^\"]+)"$/ do |id|
  asset = Asset.find(id)
  page.driver.get(asset_path(:id => asset, :format => :xml), 'Accepts' => 'application/xml')
end
