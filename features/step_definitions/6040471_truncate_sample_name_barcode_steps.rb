When /^I print the labels in the asset group$/ do
  When %Q{I follow "Print labels"}
  When %Q{I select "xyz" from "Barcode Printer"}
  When %Q{I press "Print"}
end

Given /^I have an asset group "([^"]*)" which is part of "([^"]*)"$/ do |asset_group_name, study_name|
  AssetGroup.create!(:name => asset_group_name, :study => Study.find_by_name(study_name))
end

Given /^asset group "([^"]*)" contains a "([^"]*)" called "([^"]*)"$/ do |asset_group_name, asset_type, asset_name|
  asset = eval(asset_type).create!(:name => asset_name, :barcode => "17")
  asset_group = AssetGroup.find_by_name(asset_group_name)
  asset_group.assets << asset
  asset_group.save!
end

Given /^the asset "([^"]*)" has a sanger_sample_id of "([^"]*)"$/ do |asset_id, sanger_sample_id|
  asset = Asset.find_by_id(asset_id)
  asset.sample = Sample.create!(:name => "Sample_123456", :sanger_sample_id => sanger_sample_id)
  asset.save!
end

Then /^the last printed label should contains:$/ do |table|
# decoding the soap
  label = FakeBarcodeService.instance.last_printed_label!
  label_xml = Nokogiri(label.join(""))
  items = label_xml.xpath("/env:Envelope/env:Body//labels/item")
  assert_equal 1,(items.size())
  item = items.first
  table.hashes.each do |h|
    field,value = ["Field", "Value"].map { |k| h[k] }
    nodes = item.xpath(field)
    assert_equal(1, nodes.size)
    node= nodes.first
    node_value = if href=node['href']
    refs = label_xml.xpath("//#{field}[@id='#{href.sub('#','')}']")
    refs.first.content
    else
      node.content
    end
    assert_equal(value, node_value)
  end
end


Then /^the last printed label is expected to have a name containing "([^"]*)"$/ do |label_name|
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


