# frozen_string_literal: true

require 'rails_helper'

describe 'Creating worksheets', type: :feature, cherrypicking: true, js: true do
  include RSpec::Longrun::DSL

  let(:swipecard_code) { '123456' }
  let(:user) { create :admin, swipecard_code: swipecard_code }
  let(:project) { create :project }
  let(:study) { create :study }
  let(:pipeline) { create :cherrypick_pipeline }
  let(:swipecard_code) { '123456' }
  let(:max_plates) { 17 }
  let(:robot) { create(:robot, barcode: '1111', robot_properties: [create(:robot_property, name: 'maxplates', key: 'max_plates', value: max_plates)]) }
  let(:submission) { create :submission }
  let!(:plate_template) { create :plate_template }
  let!(:plate_type) { create :plate_type }
  let(:destination_plate_barcode) { '9999' }
  let(:destination_plate_human_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode).human_barcode }
  let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, robot.max_beds, sample_count: 2) }

  before do
    plates.each do |plate|
      plate.wells.each do |well|
        create :cherrypick_request, asset: well, request_type: pipeline.request_types.first, submission: submission, study: study, project: project
      end
    end

    # need to have js enabled otherwis this doesnt get called and the destination plate doesnt get created and it fails
    stub_request(:post, "#{configatron.plate_barcode_service}plate_barcodes.xml").to_return(
      headers: { 'Content-Type' => 'text/xml' },
      body: "<plate_barcode><id>42</id><name>Barcode #{destination_plate_barcode}</name><barcode>#{destination_plate_barcode}</barcode></plate_barcode>"
    )

    (1..max_plates).each do |i|
      robot.robot_properties.create(key: "SCRC#{i}", value: i)
    end
    robot.robot_properties.create(key: 'DEST1', value: max_plates + 1)
  end

  # shared_examples_for 'a cherrypicking procedure' do
  #   it 'releases a batch' do

  #   end
  # end

  describe 'where the number of plates doesnt exceed the max beds for the robot' do
    attr_reader :batch_id

    # create user x
    # create a robot with a max beds number x
    # create a submission from plates x
    # go to page pipelines cherrypick x
    # select all plates x
    # click on create batch x
    # go to batch screen x
    # create plate template with size 96 x
    # click on select plate template x
    # select plate purpose ?
    # select plate template from drop down list x
    # select source plates type x
    # select picking robot which would be robot we created x
    # select pick by ul (micro litre) x
    # click next step x
    # should be on approve plate layout x
    # click on next step x
    # click on release batch x
    # should be page for that batch x
    # should only be one barcode in the output list x

    # click on print worksheet x
    # check that a worksheets is created x

    # for worksheet:
    # source barcode should be correct x
    # destination barcode should be correct x
    # for each well the number should match the source plate

    # go to robot verifications page
    # scan swipe card id x
    # scan robot x
    # scan worksheet x
    # scan destination plate x
    # click check x
    # got to new page x
    # scan all robot barcodes x
    # scan all source and destination and eventually control barcodes x

    # it_behaves_like 'a cherrypicking procedure'

    it 'creates worksheet' do

      step 'Access the Cherrypicking pipeline' do
        login_user(user)
        visit pipeline_path(pipeline)
        expect(page).to have_content("Pipeline #{pipeline.name}")
      end

      step 'Create a batch for cherrypicking' do
        plates.each do |plate|
          expect(page).to have_content(plate.human_barcode)
          check("Select #{plate.human_barcode} for batch")
        end
        first(:select, 'action_on_requests').select('Create Batch')
        first(:button, 'Submit').click
      end

      step 'Task 1 - Select plate template' do
        click_link 'Select Plate Template'
      end

      step 'Task 1, Step 1 - Select layout' do
        select(plate_template.name, from: 'Plate Template')
      end

      step 'Task 1, Step 2 - Select Robot' do
        select(robot.name, from: 'Picking Robot')
      end

      step 'Task 1, Step 3 - Specify quantity to pickup' do
        choose('Pick by µl')
        fill_in('micro_litre_volume_required', with: '13')
        click_button 'Next step'
      end

      step 'Task 2 - Accept layout' do
        click_button 'Next step'
      end

      step 'Task 3 - finish task' do
        click_button 'Release this batch'
        expect(page).to have_content('Batch released!')
        within('#input_assets table tbody') do
          expect(page).to have_selector('tr', count: plates.count)
        end
        within('#output_assets table tbody') do
          expect(page).to have_selector('tr', count: 1)
        end
      end

      step 'print worksheet' do
        within('.page-header') do
          @batch_id = page.find('.subtitle').text
        end

        within('#output_assets') do
          click_link 'Print worksheet'
        end

        expect(page).to have_content('This worksheet was generated')

        within('#source_plates') do
          plates.each do |plate|
            expect(page).to have_content(plate.human_barcode)
          end
        end

        within('#destination_plate') do
          expect(page).to have_content(destination_plate_barcode)
        end
      end

      step 'visit robot verifications page' do
        visit('/robot_verifications')
      end

      step 'scan user id' do
        fill_in('Scan user ID', with: swipecard_code)
      end

      step 'scan robot barcode' do
        fill_in('Scan robot', with: SBCF::SangerBarcode.new(prefix: 'RB', number: robot.barcode).machine_barcode)
      end

      step 'scan worksheet' do
        worksheet_barcode = "#{Barcode.calculate_barcode('BA', batch_id)}-1" # suffix is pick_number (1)
        fill_in('Scan worksheet', with: worksheet_barcode)
      end

      step 'scan destination plate' do
        dest_plate_barcode = SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode).human_barcode
        fill_in('Scan destination plate', with: dest_plate_barcode)
        click_on('Check')
      end

      step 'perform bed verification' do
        (1..plates.count).each do |i|
          fill_in("SCRC #{i}", with: SBCF::SangerBarcode.new(prefix: 'RB', number: i).machine_barcode)
        end
        fill_in('DEST 1', with: SBCF::SangerBarcode.new(prefix: 'RB', number: plates.count + 1).machine_barcode)

        plates.each do |plate|
          fill_in(plate.human_barcode, with: plate.human_barcode)
        end
        fill_in(destination_plate_human_barcode, with: destination_plate_human_barcode)

        click_on('Verify')
        expect(page).to have_content("Download #{robot.name.capitalize} File Step 3 of 3")
      end
    end
  end

  describe 'where the number of plates exceeds the max beds for the robot' do
    attr_reader :batch_id
    attr_reader :batch_barcode

    # create user
    # create a robot with a max beds number
    # create some plates with number max beds plus 1
    # create a submission from plates
    # go to page pipelines cherrypick
    # select all plates
    # click on create batch
    # go to batch screen
    # create plate template with size 96
    # click on select plate template
    # select plate purpose
    # select plate template from drop down list
    # select source plates type
    # select picking robot which would be robot we created with max beds number
    # select pick by ul (micro litre)
    # click next step
    # should be on approve plate layout
    # click on next step
    # click on release batch
    # should be page for that batch
    # should only be one barcode in the output list

    # click on print worksheet
    # check that two worksheets are created

    # each worksheet:
    # should have a batch barcode which is unique
    # source barcode should be correct
    # destination barcode should be correct
    # for each well the number should match the source plate

    # go to robot verifications page
    # scan swipe card id
    # scan robot
    # scan worksheet
    # scan destination plate
    # click check
    # got to new page
    # scan all robot barcodes
    # scan all source and destination and eventually control barcodes

    let(:max_plates) { 2 }
    let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, robot.max_beds + 1, sample_count: 2) }

    it 'creates worksheet' do
      step 'Access the Cherrypicking pipeline' do
        login_user(user)
        visit pipeline_path(pipeline)
        expect(page).to have_content("Pipeline #{pipeline.name}")
      end

      step 'Create a batch for cherrypicking' do
        plates.each do |plate|
          expect(page).to have_content(plate.human_barcode)
          check("Select #{plate.human_barcode} for batch")
        end
        first(:select, 'action_on_requests').select('Create Batch')
        first(:button, 'Submit').click
      end

      step 'Task 1 - Select plate template' do
        click_link 'Select Plate Template'
      end

      step 'Task 1, Step 1 - Select layout' do
        select(plate_template.name, from: 'Plate Template')
      end

      step 'Task 1, Step 2 - Select Robot' do
        select(robot.name, from: 'Picking Robot')
      end

      step 'Task 1, Step 3 - Specify quantity to pickup' do
        choose('Pick by µl')
        fill_in('micro_litre_volume_required', with: '13')
        click_button 'Next step'
      end

      step 'Task 2 - Accept layout' do
        click_button 'Next step'
      end

      step 'Task 3 - finish task' do
        click_button 'Release this batch'
        expect(page).to have_content('Batch released!')
        within('#input_assets table tbody') do
          expect(page).to have_selector('tr', count: plates.count)
        end
        within('#output_assets table tbody') do
          expect(page).to have_selector('tr', count: 1)
        end
      end

      step 'print worksheet' do
        expected_plates = {
          1 => [plates[0], plates[1]],
          2 => [plates[2]]
        }

        within('.page-header') do
          @batch_id = page.find('.subtitle').text
          @batch_barcode = Barcode.calculate_barcode('BA', batch_id)
        end
        within('#output_assets') do
          click_link 'Print worksheet'
        end

        expect(page).to have_content('This worksheet was generated')

        (1..2).each do |index|
          within("#worksheet_plate_#{destination_plate_human_barcode}_pick_#{index}") do
            within('#source_plates') do
              expected_plates[index].each do |plate|
                expect(page).to have_content(plate.human_barcode)
              end
            end

            within('#destination_plate') do
              expect(page).to have_content(destination_plate_barcode)
            end

            # check barcode
            within("#batchbarcode_#{destination_plate_human_barcode}-#{index}") do
              expect(page).to have_content("#{batch_barcode}-#{index}")
            end

            # check wells
            within('#plate_layouts') do
              cells_with_content = page.all('td', text: /.+v13.0 b0.0/)

              # check that the number each cell contains is in the expected list of source plate barcodes
              cells_with_content.each do |cell|
                barcode_numbers = expected_plates[index].map(&:barcode_number)
                number_in_cell = cell.text.split(' ')[1]

                expect(barcode_numbers).to include(number_in_cell)
              end
            end
          end
        end
      end

      step 'visit robot verifications page' do
        visit('/robot_verifications')
      end

      step 'scan user id' do
        fill_in('Scan user ID', with: swipecard_code)
      end

      step 'scan robot barcode' do
        fill_in('Scan robot', with: SBCF::SangerBarcode.new(prefix: 'RB', number: robot.barcode).machine_barcode)
      end

      step 'scan worksheet' do
        # TODO: test both worksheets - pick numbers 1 & 2 ?
        worksheet_barcode = "#{batch_barcode}-1" # suffix is pick_number (1)
        fill_in('Scan worksheet', with: worksheet_barcode)
      end

      step 'scan destination plate' do
        dest_plate_barcode = SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode).human_barcode
        fill_in('Scan destination plate', with: dest_plate_barcode)
        click_on('Check')
      end

      # step 'perform bed verification' do
      #   (1..plates.count).each do |i|
      #     fill_in("SCRC #{i}", with: SBCF::SangerBarcode.new(prefix: 'RB', number: i).machine_barcode)
      #   end
      #   fill_in('DEST 1', with: SBCF::SangerBarcode.new(prefix: 'RB', number: plates.count + 1).machine_barcode)

      #   plates.each do |plate|
      #     fill_in(plate.human_barcode, with: plate.human_barcode)
      #   end
      #   fill_in(destination_plate_human_barcode, with: destination_plate_human_barcode)

      #   click_on('Verify')
      #   expect(page).to have_content("Download #{robot.name.capitalize} File Step 3 of 3")
      # end
    end
  end

  # describe 'a single cherrypicking' do
  #   let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, robot.max_beds, sample_count: 2) }
  #   it_behaves_like 'a cherrypicking procedure'
  # end
end
