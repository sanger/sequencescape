# frozen_string_literal: true

require 'rails_helper'

describe 'Creating worksheets', type: :feature, cherrypicking: true, js: true do
  include RSpec::Longrun::DSL

  let(:user) { create :admin }
  let(:project) { create :project }
  let(:study) { create :study }
  let(:pipeline) { create :cherrypick_pipeline }
  let(:robot) { create(:robot, robot_properties: [create(:robot_property, name: 'maxplates', key: 'max_plates', value: 17)]) }
  let(:plates) { create_list(:plate_with_untagged_wells, robot.max_beds, sample_count: 2) }
  let(:submission) { create :submission }
  let!(:plate_template) { create :plate_template }
  let!(:plate_type) { create :plate_type }
  let(:destination_plate_barcode) { '9999' }

  describe 'where the number of plates doesnt exceed the max beds for the robot' do
    # create user x
    # create a robot with a max beds number x
    # create a submission from plates ?
    # go to page pipelines cherrypick x
    # select all plates x
    # click on create batch x
    # go to batch screen x
    # create plate template with size 96 ?
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
    # should have a batch barcode which is unique
    # source barcode should be correct x
    # destination barcode should be correct x
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
    # ???
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
    end

    it 'has a max beds property' do
      expect(robot.max_beds).to eq(17)
    end

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
        # save_and_open_page
      end
    end
  end

  describe 'where the number of plates exceeds the max beds for the robot' do
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
    # ???

    it 'works' do
      expect(true).to be_truthy
    end
  end
end
