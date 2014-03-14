Given /^I have a lot type for testing called "(.*?)"$/ do |name|
  LotType.create!(
    :name           => name,
    :target_purpose => QcablePlatePurpose.find_by_name('Tag Plate'),
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

Given /^I am set up for testing qcable ordering$/ do
  lot = Lot.find_by_lot_number('1234567890')
  user = User.last
  step %Q{the plate barcode webservice returns "1000001..1000009"}
  step %Q{a robot exists}
  qccreate = QcableCreator.create!(:lot=>lot,:user=>user,:count=>6)

  step %Q{all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"}

  sqc_a = Stamp::StampQcable.new(:bed=>'1',:order=>1,:qcable=>qccreate.qcables[0])
  sqc_b = Stamp::StampQcable.new(:bed=>'2',:order=>2,:qcable=>qccreate.qcables[4])
  stamp_a = Stamp.create!(:user=>user,:tip_lot=>'1234556',:stamp_qcables => [sqc_a,sqc_b],:lot=>lot, :robot=>Robot.last)


  step %Q{all of this is happening at exactly "23-Oct-2010 23:20:00+01:00"}

  sqc_c = Stamp::StampQcable.new(:bed=>'5',:order=>1,:qcable=>qccreate.qcables[3])
  sqc_d = Stamp::StampQcable.new(:bed=>'3',:order=>2,:qcable=>qccreate.qcables[2])
  stamp_b = Stamp.create!(:user=>user,:tip_lot=>'1234556',:stamp_qcables => [sqc_c,sqc_d],:lot=>lot, :robot=>Robot.last)

end

Given /^I have a qcable$/ do
  lot = Lot.find_by_lot_number('1234567890')
  user = User.last
  step %{the UUID of the next plate created will be "55555555-6666-7777-8888-000000000004"}
  step %Q{the plate barcode webservice returns "1000001"}
  QcableCreator.create!(:lot=>lot,:user=>user,:count=>1)
end

Given /^I have two qcables$/ do
  lot = Lot.find_by_lot_number('1234567890')
  user = User.last
  step %Q{the plate barcode webservice returns "1000001"}
  step %Q{the plate barcode webservice returns "1000002"}
  QcableCreator.create!(:lot=>lot,:user=>user,:count=>2)
end

Given /^I have a robot for testing called "(.*?)"$/ do |name|
  Robot.create!(:name=>name,:location=>'Somewhere',:barcode=>123) do |robot|
    robot.robot_properties.build([
      {:name=>'Max Number of plates',:key=>'max_plates',:value=>'3'},
      {:key=>'SCRC1',:value=>'20001'},
      {:key=>'DEST1',:value=>'20002'},
      {:key=>'DEST2',:value=>'20003'}
    ])
  end
end
