Given /^the barcode for the sample tube "([^\"]+)" is "([^\"]+)"$/ do |name, barcode|
  sample_tube = SampleTube.find_by_name(name) or raise StandardError, "Cannot find sample tube #{name.inspect}"
  sample_tube.update_attributes!(:barcode => barcode)
end

Given /^tube "([^"]*)" has a public name of "([^"]*)"$/ do |name, public_name|
  Asset.find_by_name(name).update_attributes!(:public_name => public_name)
end

Given /^(?:I have )?a (sample|library) tube called "([^\"]+)"$/ do |tube_type, name|
  Factory(:"#{ tube_type }_tube", :name => name)
end

Given /^(?:I have )?a well called "([^\"]+)"$/ do |name|
  sample = Factory(:sample)
  Factory(:well, :name => name, :sample => sample)
end

Then /^the name of (the .+) should be "([^\"]+)"$/ do |asset, name|
  assert_equal(name, asset.name)
end

Given /^there is an asset link between "([^"]*)" and "([^"]*)"$/ do |source, target|
  AssetLink.create_edge(Plate.find_by_name(source),Plate.find_by_name(target))
end

