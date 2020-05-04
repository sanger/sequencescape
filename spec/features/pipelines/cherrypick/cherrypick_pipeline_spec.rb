# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'cherrypick pipeline', js: true do
  include FetchTable
  include RSpec::Longrun::DSL

  let(:user) { create :admin, barcode: 'ID41440E' }
  let(:project) { create :project, name: 'Test project' }
  let(:study) { create :study }
  let(:pipeline_name) { pipeline.name }
  let(:pipeline) { create :cherrypick_pipeline }
  let(:submission) { create :submission }
  let(:plate1) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '1' }
  let(:plate2) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '10' }
  let(:plate3) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '5' }
  let(:plates) { [plate1, plate2, plate3] }
  let(:barcode) { 99999 }
  let(:robot) { create :robot, barcode: '444' }
  let!(:plate_template) { create :plate_template }
  let!(:target_purpose) { create :plate_purpose }

  before do
    step 'Before' do
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
  end

  it 'requests leave inbox' do
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
    expect(page).not_to have_content('DN1S')
  end

  it 'Pick by µl - 13' do
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
    choose('Pick by µl')
    fill_in('micro_litre_volume_required', with: '13')
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')
  end

  it 'Pick by ng/µl: 65, conc default' do
    create :plate_type, name: 'ABgene_0765', maximum_volume: 800
    create :plate_type, name: 'Custom Type'

    login_user(user)

    step 'Set up the batch' do
      visit pipeline_path(pipeline)
      check('Select DN1S for batch')
      check('Select DN10I for batch')
      check('Select DN5W for batch')
      first(:select, 'action_on_requests').select('Create Batch')
      first(:button, 'Submit').click
    end
    click_link 'Select Plate Template'

    step 'Follow the pipeline' do
      select(plate_template.name, from: 'Plate Template')
      select(target_purpose.name, from: 'Output plate purpose')
      choose('Pick by ng/µl')
      fill_in('Volume Required', with: '65')
      within('#pick_by_nano_grams_per_micro_litre') do
        fill_in('Robot Minimum Picking Volume', with: '1.0')
      end

      click_button 'Next step'
      click_button 'Next step'
      click_button 'Release this batch'
      expect(page).to have_content('Batch released!')
    end

    batch = Batch.last
    batch.update!(barcode: Barcode.number_to_human(550000555760))

    step 'Robot verification step 1' do
      visit robot_verifications_path
      fill_in('Scan user ID', with: '2470041440697')
      fill_in('Scan Tecan robot', with: '4880000444853')
      fill_in('Scan worksheet', with: '550000555760')
      fill_in('Scan destination plate', with: 'DN99999F')

      click_button 'Check'
      # Check the page content in the first step as this indicates when it has completed
      expect(page).to have_content('Scan Robot Beds And Plates')
    end

    step 'Robot verification step 2' do
      plate_type_list = PlateType.all.pluck(:name).join(' ')
      table = [['Bed', 'Scanned robot beds', 'Plate ID', 'Scanned plates', 'Plate type'],
               ['SCRC 1', '', 'DN1S', '', plate_type_list],
               ['SCRC 2', '', 'DN10I', '', plate_type_list],
               ['SCRC 3', '', 'DN5W', '', plate_type_list],
               ['DEST 1', '', 'DN99999F', '', plate_type_list]]

      expect(fetch_table('table#source_beds')).to eq(table)

      fill_in('SCRC 1', with: '4880000001780')
      fill_in('DN1S', with: 'DN1S')
      fill_in('SCRC 2', with: '4880000002794')
      fill_in('DN5W', with: 'DN5W')
      fill_in('SCRC 3', with: '4880000003807')
      fill_in('DN10I', with: 'DN10I')
      fill_in('DEST 1', with: '4880000020729')
      fill_in('DN99999F', with: 'DN99999F')

      select 'Custom Type', from: 'destination_plate_types[DN99999F]'

      step 'Wait for verify' do
        click_button 'Verify'
        expect(page).to have_content 'Download TECAN file'
      end
    end

    step 'Robot verification step 3' do
      click_link('Download TECAN file')
      # Tecan file generation is slow. Can probably be sped up, but for the moment...
      generated_file = DownloadHelpers.downloaded_file("#{batch.id}_batch_DN99999F.gwl")
      generated_lines = generated_file.lines
      # Shift off the comment lines
      generated_lines.shift(2)

      expected_file = <<~TECAN
        C;
        C; This file created by user_abc6 on 2018-06-14 11:17:04 +0100
        C;
        A;BUFF;;96-TROUGH;1;;49.1
        D;DN99999F;;Custom Type;1;;49.1
        W;
        A;BUFF;;96-TROUGH;2;;49.2
        D;DN99999F;;Custom Type;2;;49.2
        W;
        A;BUFF;;96-TROUGH;3;;49.1
        D;DN99999F;;Custom Type;3;;49.1
        W;
        A;BUFF;;96-TROUGH;4;;49.2
        D;DN99999F;;Custom Type;4;;49.2
        W;
        A;BUFF;;96-TROUGH;5;;49.1
        D;DN99999F;;Custom Type;5;;49.1
        W;
        A;BUFF;;96-TROUGH;6;;49.2
        D;DN99999F;;Custom Type;6;;49.2
        W;
        C;
        A;DN1S;;ABgene 0765;1;;15.9
        D;DN99999F;;Custom Type;1;;15.9
        W;
        A;DN1S;;ABgene 0765;2;;15.8
        D;DN99999F;;Custom Type;2;;15.8
        W;
        A;DN10I;;ABgene 0765;1;;15.9
        D;DN99999F;;Custom Type;3;;15.9
        W;
        A;DN10I;;ABgene 0765;2;;15.8
        D;DN99999F;;Custom Type;4;;15.8
        W;
        A;DN5W;;ABgene 0765;1;;15.9
        D;DN99999F;;Custom Type;5;;15.9
        W;
        A;DN5W;;ABgene 0765;2;;15.8
        D;DN99999F;;Custom Type;6;;15.8
        W;
        C;
        C; SCRC1 = DN1S
        C; SCRC2 = DN10I
        C; SCRC3 = DN5W
        C;
        C; DEST1 = DN99999F
      TECAN

      expected_file_lines = expected_file.lines
      # Shift off the comment lines
      expected_file_lines.shift(2)

      expect(generated_lines.length).to eq(expected_file_lines.length)

      expected_file_lines.each_with_index do |expected_line, index|
        expect(generated_lines[index]).to eq(expected_line), "Error on line #{index + 2} in #{expected_file}"
      end
    end
  end

  it 'Pick by ng' do
    create :plate_type, name: 'ABgene_0800', maximum_volume: 800
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
    choose('Pick by ng')
    within('#pick_by_nano_grams') do
      fill_in('Robot Minimum Picking Volume', with: '2.0')
      fill_in('Quantity to pick', with: 10000)
      fill_in('Minimum Volume', with: 20)
      fill_in('Maximum Volume', with: 150)
    end
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')

    click_link('Tecan file')
    batch = Batch.last
    # We proceed to check the generated TECAN file here.
    # This is an import of an old test which appeared to address
    # a bug in which the maximum picking volume would not go above
    # 13ul. Unfortunately there is no further information recorded.
    # Maintaining this as an integration test, as it could be a case
    # of values getting passed through from the front end incorrectly.
    generated_file = DownloadHelpers.downloaded_file("#{batch.id}_batch_DN99999F.gwl")
    generated_lines = generated_file.lines
    # Shift off the comment lines
    generated_lines.shift(2)

    expected_file = <<~TECAN
      C;
      C; This file created by user_abc12 on 2018-06-14 17:09:13 +0100
      C;
      A;DN1S;;ABgene 0800;1;;30.0
      D;DN99999F;;ABgene 0800;1;;30.0
      W;
      A;DN1S;;ABgene 0800;2;;31.0
      D;DN99999F;;ABgene 0800;2;;31.0
      W;
      A;DN10I;;ABgene 0800;1;;30.0
      D;DN99999F;;ABgene 0800;3;;30.0
      W;
      A;DN10I;;ABgene 0800;2;;31.0
      D;DN99999F;;ABgene 0800;4;;31.0
      W;
      A;DN5W;;ABgene 0800;1;;30.0
      D;DN99999F;;ABgene 0800;5;;30.0
      W;
      A;DN5W;;ABgene 0800;2;;31.0
      D;DN99999F;;ABgene 0800;6;;31.0
      W;
      C;
      C; SCRC1 = DN1S
      C; SCRC2 = DN10I
      C; SCRC3 = DN5W
      C;
      C; DEST1 = DN99999F
    TECAN

    expected_file_lines = expected_file.lines
    # Shift off the comment lines
    expected_file_lines.shift(2)

    expect(generated_lines.length).to eq(expected_file_lines.length)

    expected_file_lines.each_with_index do |expected_line, index|
      expect(generated_lines[index]).to eq(expected_line)
    end

    within('#output_assets') do
      click_link 'Show plate'
    end

    expect(page).to have_content(plate1.contained_samples.first.name)
  end
end
