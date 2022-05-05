# frozen_string_literal: true

Given /^I have a lot type for testing called "(.*?)"$/ do |name|
  LotType.create!(
    name: name,
    target_purpose: QcablePlatePurpose.find_by(name: 'Tag Plate'),
    template_class: 'TagLayoutTemplate'
  )
end

Given /^I have a reporter lot type for testing called "(.*?)"$/ do |name|
  LotType.create!(
    name: name,
    target_purpose: QcablePlatePurpose.find_by(name: 'Reporter Plate'),
    template_class: 'PlateTemplate'
  )
end

Given /^the UUID for the lot type "(.*?)" is "(.*?)"$/ do |name, uuid|
  set_uuid_for(LotType.find_by(name: name), uuid)
end

Given /^the lot exists with the attributes:$/ do |table|
  settings = table.hashes.first
  Lot.create!(
    lot_number: settings['lot_number'],
    lot_type: LotType.find_by(name: settings['lot_type']),
    received_at: settings['received_at'],
    template:
      TagLayoutTemplate.find_by(name: settings['template']) || PlateTemplate.find_by(name: settings['template']),
    user: User.last
  )
end

Given /^the UUID for the lot with lot number "(.*?)" is "(.*?)"$/ do |lot_number, uuid|
  set_uuid_for(Lot.find_by(lot_number: lot_number), uuid)
end

Given /^lot "(.*?)" has (\d+) created qcables$/ do |lot_number, qcable_count|
  lot = Lot.find_by(lot_number: lot_number)
  QcableCreator.create!(lot: lot, user: User.last, count: qcable_count.to_i)
end

Then /^the qcables in lot "(.*?)" should be "(.*?)"$/ do |lot_number, target_state|
  Lot.find_by(lot_number: lot_number).qcables.each { |qcable| assert_equal target_state, qcable.state }
end

Given /^all qcables in lot "(.*?)" are "(.*?)"$/ do |lot_number, state|
  Lot.find_by(lot_number: lot_number).qcables.each { |qcable| qcable.update!(state: state) }
end

Given /^I am set up for testing qcable ordering$/ do
  lot = Lot.find_by(lot_number: '1234567890')
  user = User.last
  9.times { |pos| step "the Baracoda barcode service returns \"SQPD-100000#{pos + 1}\"" }
  step 'a robot exists'
  qccreate = QcableCreator.create!(lot: lot, user: user, count: 6)

  step 'all of this is happening at exactly "23-Oct-2010 23:00:00+01:00"'

  sqc_a = Stamp::StampQcable.new(bed: '1', order: 1, qcable: qccreate.qcables[0])
  sqc_b = Stamp::StampQcable.new(bed: '2', order: 2, qcable: qccreate.qcables[4])
  stamp_a = Stamp.create!(user: user, tip_lot: '1234556', stamp_qcables: [sqc_a, sqc_b], lot: lot, robot: Robot.last)

  step 'all of this is happening at exactly "23-Oct-2010 23:20:00+01:00"'

  sqc_c = Stamp::StampQcable.new(bed: '5', order: 1, qcable: qccreate.qcables[3])
  sqc_d = Stamp::StampQcable.new(bed: '3', order: 2, qcable: qccreate.qcables[2])
  stamp_b = Stamp.create!(user: user, tip_lot: '1234556', stamp_qcables: [sqc_c, sqc_d], lot: lot, robot: Robot.last)
end

Given /^I have a qcable$/ do
  lot = Lot.find_by(lot_number: '1234567890')
  user = User.last
  step 'the UUID of the next plate created will be "55555555-6666-7777-8888-000000000004"'
  step 'the Baracoda barcode service returns "SQPD-1000001"'
  QcableCreator.create!(lot: lot, user: user, count: 1)
end

Given /^I have two qcables$/ do
  lot = Lot.find_by(lot_number: '1234567890')
  user = User.last
  step 'the Baracoda barcode service returns "SQPD-1000001"'
  step 'the Baracoda barcode service returns "SQPD-1000002"'
  QcableCreator.create!(lot: lot, user: user, count: 2)
end

Given /^I have a robot for testing called "(.*?)"$/ do |name|
  Robot.create!(name: name, location: 'Somewhere', barcode: 123) do |robot|
    robot.robot_properties.build(
      [
        { name: 'Max Number of plates', key: 'max_plates', value: '3' },
        { key: 'SCRC1', value: '20001' },
        { key: 'DEST1', value: '20002' },
        { key: 'DEST2', value: '20003' }
      ]
    )
  end
end

Given /^I have a qc library created$/ do
  lot = Lot.find_by(lot_number: '1234567890')
  lot_b = Lot.find_by(lot_number: '1234567891')
  user = User.last
  step 'the Baracoda barcode service returns "SQPD-1000001"'
  step 'the Baracoda barcode service returns "SQPD-1000002"'
  qca = QcableCreator.create!(lot: lot, user: user, count: 1)
  qcb = QcableCreator.create!(lot: lot_b, user: user, count: 1)

  tag_plate = qca.qcables.first.asset
  reporter_plate = qcb.qcables.first.asset

  tag_plate.update!(plate_purpose: PlatePurpose.find_by(name: 'Tag PCR'))
  Transfer::BetweenPlates.create!(
    user: user,
    source: reporter_plate,
    destination: tag_plate,
    transfers: {
      'A1' => 'A1'
    }
  )
  stc =
    SpecificTubeCreation.create!(parent: tag_plate, child_purposes: [Tube::Purpose.find_by(name: 'Tag MX')], user: user)
  batch =
    Batch
      .new(pipeline: Pipeline.find_by(name: 'MiSeq sequencing'))
      .tap do |batch|
        batch.id = 12_345
        batch.save!
      end
  FactoryBot.create :request_without_submission, asset: stc.children.first, batch: batch
  # Batch.find(12345).batch_requests.create!(:request=>Request.create!(:asset=>stc.children.first),:position=>1)
end
Given /^the library is testing a reporter$/ do
  lot = Lot.find_by(lot_number: '1234567890')
  lot_b = Lot.find_by(lot_number: '1234567891')
  lot.qcables.first.update!(state: 'exhausted')
  lot_b.qcables.first.update!(state: 'pending')
end

Given /^the user with UUID "(.*?)" is a 'qa_manager'$/ do |uuid|
  Uuid.find_by(external_id: uuid).resource.roles.create(name: 'qa_manager')
end

Then '{plate_name} has the parent {string}' do |child, parent_name|
  assert_equal parent_name, child.parents.first.try(:name) || 'No plate found'
end
