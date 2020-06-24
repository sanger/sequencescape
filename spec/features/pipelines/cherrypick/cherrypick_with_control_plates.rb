# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'cherrypick pipeline with control plates', js: true do
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
  let(:plate3) { create  :control_plate, sample_count: 2, barcode: '5' }
  let(:plates) { [plate1, plate2, plate3] }
  let(:barcode) { 99999 }
  let!(:robot) { create :hamilton, barcode: '444' }
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
    end
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
      select(robot.name, from: 'Robot')
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
      fill_in('Scan robot', with: '4880000444853')
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
               ['CTRL 1', '', 'DN5W', '', plate_type_list],
               ['DEST 1', '', 'DN99999F', '', plate_type_list]]

      expect(fetch_table('table#source_beds')).to eq(table)

      fill_in('SCRC 1', with: '4880000001780')
      fill_in('DN1S', with: 'DN1S')
      fill_in('SCRC 2', with: '4880000002794')
      fill_in('DN10I', with: 'DN10I')
      fill_in('CTRL 1', with: '4880000025779')
      fill_in('DN5W', with: 'DN5W')
      fill_in('DEST 1', with: '4880000026783')
      fill_in('DN99999F', with: 'DN99999F')

      select 'Custom Type', from: 'plate_types[DN99999F]'

      step 'Wait for verify' do
        click_button 'Verify'
        expect(page).to have_content "Download #{robot.name} File"
      end
    end

    step 'Robot verification step 3' do
      click_link("Download #{robot.name} File")
      # Tecan file generation is slow. Can probably be sped up, but for the moment...
      generated_file = DownloadHelpers.downloaded_file("#{batch.id}_batch_DN99999F.csv")
      generated_lines = generated_file.lines

      expected_file = <<~FILE
        SourcePlateID,SourceWellID,SourcePlateType,SourcePlateVolume,DestinationPlateID,DestinationWellID,DestinationPlateType,DestinationPlateVolume,WaterVolume
        DN1S,A1,ABgene 0765,15.85,DN99999F,A1,Custom Type,15.85,49.15
        DN1S,B1,ABgene 0765,15.78,DN99999F,B1,Custom Type,15.78,49.22
        DN10I,A1,ABgene 0765,15.85,DN99999F,C1,Custom Type,15.85,49.15
        DN10I,B1,ABgene 0765,15.78,DN99999F,D1,Custom Type,15.78,49.22
        DN5W,A1,ABgene 0765,15.85,DN99999F,E1,Custom Type,15.85,49.15
        DN5W,B1,ABgene 0765,15.78,DN99999F,F1,Custom Type,15.78,49.22
      FILE

      expected_file_lines = expected_file.lines

      expect(generated_lines.length).to eq(expected_file_lines.length)

      expected_file_lines.each_with_index do |expected_line, index|
        expect(generated_lines[index]).to eq(expected_line), "Error on line #{index + 2} in #{expected_file}"
      end
    end
  end
end
