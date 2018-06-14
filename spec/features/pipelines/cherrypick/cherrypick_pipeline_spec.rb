# frozen_string_literal: true

require 'rails_helper'
require 'pry'

feature 'cherrypick pipeline', js: true do
  include FetchTable

  let(:user) { create :admin, barcode: 'ID41440E' }
  let(:project) { create :project, name: 'Test project' }
  let(:study) { create :study }
  let(:pipeline_name) { 'Cherrypick' }
  let(:pipeline) { Pipeline.find_by(name: pipeline_name) }
  let(:submission) { create :submission }
  let(:plate1) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '1' }
  let(:plate2) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '10' }
  let(:plate3) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '5' }
  let(:plates) { [plate1, plate2, plate3] }
  let(:barcode) { 99999 }
  let(:robot) { create :robot, barcode: '444' }
  let!(:plate_template) { create :plate_template }
  let!(:target_purpose) { create :plate_purpose }

  before(:each) do
    assets = plates.each_with_object([]) do |plate, wells|
      wells.concat(plate.wells)
      plate.wells.each_with_index do |well, index|
        well.well_attribute.update!(
          measured_volume: 30 + (index % 30),
          current_volume: 30 + (index % 30),
          concentration: 205 + (index % 50)
        )
      end
    end
    assets.each do |asset|
      create :cherrypick_request, asset: asset, request_type: pipeline.request_types.first, submission: submission, study: study, project: project
    end

    stub_request(:post, "#{configatron.plate_barcode_service}plate_barcodes.xml").to_return(
      headers: { 'Content-Type' => 'text/xml' },
      body: "<plate_barcode><id>42</id><name>Barcode #{barcode}</name><barcode>#{barcode}</barcode></plate_barcode>"
    )

    robot.robot_properties.create(key: 'max_plates', value: '21')
    robot.robot_properties.create(key: 'SCRC1', value: '1')
    robot.robot_properties.create(key: 'SCRC2', value: '2')
    robot.robot_properties.create(key: 'SCRC3', value: '3')
    robot.robot_properties.create(key: 'DEST1', value: '20')
  end

  scenario 'requests leave inbox' do
    login_user(user)
    visit pipeline_path(pipeline)
    expect(page).to have_content("Pipeline #{pipeline_name}")
    expect(page).to have_content('DN1S')
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Back to pipeline'
    expect(page).to_not have_content('DN1S')
  end

  scenario 'required volume is 13' do
    login_user(user)
    visit pipeline_path(pipeline)
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select(plate_template.name, from: 'Plate Template')
    select(target_purpose.name, from: 'Output plate purpose')
    choose('cherrypick_action_micro_litre')
    fill_in('micro_litre_volume_required', with: '13')
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')
  end

  scenario 'required volume is 65 by ng per ul' do
    create :plate_type, name: 'ABgene_0765', maximum_volume: 800
    plate_type_list = PlateType.all.pluck(:name).join(' ')
    login_user(user)
    visit pipeline_path(pipeline)
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select(plate_template.name, from: 'Plate Template')
    select(target_purpose.name, from: 'Output plate purpose')
    fill_in('nano_grams_per_micro_litre_volume_required', with: '65')
    fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: '1.0')
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')

    batch = Batch.last
    batch.update!(barcode: Barcode.number_to_human(550000555760))

    visit robot_verifications_path
    fill_in('Scan user ID', with: '2470041440697')
    fill_in('Scan Tecan robot', with: '4880000444853')
    fill_in('Scan worksheet', with: '550000555760')
    fill_in('Scan destination plate', with: '1220099999705')
    click_button 'Check'
    expect(page).to have_content('Scan robot beds and plates')

    table = [['Bed', 'Scanned robot beds', 'Plate ID', 'Scanned plates', 'Plate type'],
             ['SCRC 1', '', '1220000001831', '', plate_type_list],
             ['SCRC 2', '', '1220000010734', '', plate_type_list],
             ['SCRC 3', '', '1220000005877', '', plate_type_list],
             ['DEST 1', '', '1220099999705', '', 'ABgene_0800']]

    expect(fetch_table('table#source_beds')).to eq(table)

    fill_in('SCRC 1', with: '4880000001780')
    fill_in('1220000001831', with: '1220000001831')
    fill_in('SCRC 2', with: '4880000002794')
    fill_in('1220000005877', with: '1220000005877')
    fill_in('SCRC 3', with: '4880000003807')
    fill_in('1220000010734', with: '1220000010734')
    fill_in('DEST 1', with: '4880000020729')
    fill_in('1220099999705', with: '1220099999705')

    click_button 'Verify'
    click_link('Download TECAN file')
    # Tecan file generation is slow. Can probably be sped up, but for the moment...
    generated_file = DownloadHelpers.downloaded_file("#{batch.id}_batch_DN99999F.gwl")
    generated_lines = generated_file.lines
    # Shift off the comment lines
    generated_lines.shift(2)
    expect(generated_lines).to be_truthy
    expected_file = <<~TECAN
      C;
      C; This file created by user_abc6 on 2018-06-14 11:17:04 +0100
      C;
      A;BUFF;;96-TROUGH;1;;49.1
      D;1220099999705;;ABgene 0800;1;;49.1
      W;
      A;BUFF;;96-TROUGH;2;;49.2
      D;1220099999705;;ABgene 0800;2;;49.2
      W;
      A;BUFF;;96-TROUGH;3;;49.1
      D;1220099999705;;ABgene 0800;3;;49.1
      W;
      A;BUFF;;96-TROUGH;4;;49.2
      D;1220099999705;;ABgene 0800;4;;49.2
      W;
      A;BUFF;;96-TROUGH;5;;49.1
      D;1220099999705;;ABgene 0800;5;;49.1
      W;
      A;BUFF;;96-TROUGH;6;;49.2
      D;1220099999705;;ABgene 0800;6;;49.2
      W;
      C;
      A;1220000001831;;ABgene 0765;1;;15.9
      D;1220099999705;;ABgene 0800;1;;15.9
      W;
      A;1220000001831;;ABgene 0765;2;;15.8
      D;1220099999705;;ABgene 0800;2;;15.8
      W;
      A;1220000010734;;ABgene 0765;1;;15.9
      D;1220099999705;;ABgene 0800;3;;15.9
      W;
      A;1220000010734;;ABgene 0765;2;;15.8
      D;1220099999705;;ABgene 0800;4;;15.8
      W;
      A;1220000005877;;ABgene 0765;1;;15.9
      D;1220099999705;;ABgene 0800;5;;15.9
      W;
      A;1220000005877;;ABgene 0765;2;;15.8
      D;1220099999705;;ABgene 0800;6;;15.8
      W;
      C;
      C; SCRC1 = 1220000001831
      C; SCRC2 = 1220000010734
      C; SCRC3 = 1220000005877
      C;
      C; DEST1 = 1220099999705
      TECAN

    expected_file_lines = expected_file.lines
    # Shift off the comment lines
    expected_file_lines.shift(2)

    expect(generated_lines.length).to eq(expected_file_lines.length)

    expected_file_lines.each_with_index do |expected_line, index|
      expect(expected_line).to eq(generated_lines[index])
    end
  end

  scenario 'robot minimum picking volume is 2.0 by ng' do
    login_user(user)
    visit pipeline_path(pipeline)
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select(plate_template.name, from: 'Plate Template')
    select(target_purpose.name, from: 'Output plate purpose')
    choose('cherrypick_action_nano_grams')
    fill_in('nano_grams_robot_minimum_picking_volume', with: '2.0')
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')
    within('#output_assets') do
      click_link 'Show plate'
    end
    expect(page).to have_content(plate1.contained_samples.first.name)
  end
end
