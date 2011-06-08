When /^I print the labels in the asset group$/ do
  When %Q{I follow "Print labels"}
  When %Q{I select "xyz" from "Barcode Printer"}
  When %Q{I press "Print"}
end

Given /^I have an asset group "([^"]*)" which is part of "([^"]*)"$/ do |asset_group_name, study_name|
  AssetGroup.create!(:name => asset_group_name, :study => Study.find_by_name(study_name))
end

Given /^asset group "([^"]*)" contains a "([^"]*)" called "([^"]*)"$/ do |asset_group_name, asset_type, asset_name|
  asset = eval(asset_type).create!(:name => asset_name)
  asset_group = AssetGroup.find_by_name(asset_group_name)
  asset_group.assets << asset
  asset_group.save!
end

Given /^the asset "([^"]*)" has a sanger_sample_id of "([^"]*)"$/ do |asset_id, sanger_sample_id|
  asset = Asset.find(asset_id)
  asset.aliquots.clear
  asset.aliquots.create!(:sample => Sample.create!(:name => "Sample_123456", :sanger_sample_id => sanger_sample_id))
end

Then /^the printed label is expected to have a name of "([^"]*)"$/ do |label_name|
  assert_equal label_name, BarcodeLabel.labels.last.study
end


Then /^the printed label is expected to have a name containing "([^"]*)"$/ do |label_name|
  assert_not_nil BarcodeLabel.labels.last.study.match(label_name)
end

BarcodeLabel
class BarcodeLabel
  @@labels = []

  def self.labels
    @@labels
  end 

  def initialize_with_instance_store(options = {})
    initialize_without_instance_store(options)
    @@labels << self
  end
  alias_method_chain(:initialize, :instance_store)
end


