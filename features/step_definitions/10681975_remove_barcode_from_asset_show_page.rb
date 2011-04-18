Given /^an asset with name "([^"]*)", EAN barcode "([^"]*)"$/ do |name_asset, barcode|
   asset = Factory :asset, :name => name_asset, :barcode => barcode
end
