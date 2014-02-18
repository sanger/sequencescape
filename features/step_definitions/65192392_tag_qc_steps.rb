Given /^I have a lot type for testing called "(.*?)"$/ do |name|
  LotType.create!(
    :name           => name,
    :target_purpose => PlatePurpose.stock_plate_purpose,
    :template_class => 'TagLayoutTemplate'
  )
end

Given /^the UUID for the lot type "(.*?)" is "(.*?)"$/ do |name, uuid|
  set_uuid_for(LotType.find_by_name(name),uuid)
end

Given /^the lot exists with the attributes:$/ do |table|
  settings = table.hashes.first
  Lot.create!(
    :lot_number  => settings['lot_number'],
    :lot_type    => LotType.find_by_name(settings['lot_type']),
    :received_at => settings['received_at'],
    :template    => TagLayoutTemplate.find_by_name(settings['template']),
    :user        => User.last
    )
end

Given /^the UUID for the lot with lot number "(.*?)" is "(.*?)"$/ do |lot_number, uuid|
  set_uuid_for(Lot.find_by_lot_number(lot_number),uuid)
end

Given /^lot "(.*?)" has (\d+) created qcables$/ do |lot_number, qcable_count|
  lot = Lot.find_by_lot_number(lot_number)
  QcableCreator.create!(:lot=>lot,:user=>User.last,:count=>qcable_count.to_i)
end

Then /^the qcables in lot "(.*?)" should be "(.*?)"$/ do |lot_number, target_state|
  Lot.find_by_lot_number(lot_number).qcables.each do |qcable|
    assert_equal target_state, qcable.state
  end
end

Given /^all qcables in lot "(.*?)" are "(.*?)"$/ do |lot_number, state|
  Lot.find_by_lot_number(lot_number).qcables.each do |qcable|
    qcable.update_attributes!(:state=>state)
  end
end
