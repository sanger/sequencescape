#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012 Genome Research Ltd.
When /^I print the labels in the asset group$/ do
  step(%Q{I follow "Print labels"})
  step(%Q{I select "xyz" from "Barcode Printer"})
  step(%Q{I press "Print"})
end

Given /^I have an asset group "([^"]*)" which is part of "([^"]*)"$/ do |asset_group_name, study_name|
  AssetGroup.create!(:name => asset_group_name, :study => Study.find_by_name(study_name))
end

Given /^asset group "([^\"]*)" contains a "([^\"]*)" called "([^\"]*)"$/ do |asset_group_name, asset_type, asset_name|
  asset = eval(asset_type).create!(:name => asset_name, :barcode => "17")
  asset_group = AssetGroup.find_by_name(asset_group_name)
  asset_group.assets << asset
  asset_group.save!
end

Given /^the asset "([^\"]*)" has a sanger_sample_id of "([^\"]*)"$/ do |asset_id, sanger_sample_id|
  asset = Asset.find(asset_id)
  asset.aliquots.clear
  asset.aliquots.create!(:sample => Sample.create!(:name => "Sample_123456", :sanger_sample_id => sanger_sample_id))
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
    #we assert to display an error message, but the true test is the regexp
    assert_equal(value, node_value) unless node_value =~ /^#{value}$/
  end
end
