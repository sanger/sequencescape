# frozen_string_literal: true

require 'rails_helper'

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

describe 'Creating worksheets', type: :feature, cherrypicking: true do

  let(:user) { create :admin }
  let(:project) { create :project }
  let(:study) { create :study }
  let(:pipeline) { create :cherrypick_pipeline }
  let(:robot) { create(:robot, robot_properties: [create(:robot_property, name: 'maxplates', key: 'max_plates', value: 17)]) }
  let(:plates) { create_list(:plate_with_untagged_wells, robot.max_beds, sample_count: 2)}
  let(:submission) { create :submission }
  let!(:plate_template) { create :plate_template }

  describe 'where the number of plates doesnt exceed the max beds for the robot' do

    before(:each) do
      plates.each do |plate|
        plate.wells.each do |well|
          create :cherrypick_request, asset: well, request_type: pipeline.request_types.first, submission: submission, study: study, project: project
        end
      end
    end

    it 'has a max beds property' do
      expect(robot.max_beds).to eq(17)
    end

    it 'should create worksheet' do
      login_user(user)
      visit pipeline_path(pipeline)
      expect(page).to have_content("Pipeline #{pipeline.name}")
      plates.each do |plate|
        expect(page).to have_content(plate.human_barcode)
        check("Select #{plate.human_barcode} for batch")
      end
      first(:select, 'action_on_requests').select('Create Batch')
      first(:button, 'Submit').click
      click_link 'Select Plate Template'
      select(plate_template.name, from: 'Plate Template')
      select(robot.name, from: 'Picking Robot')
      # now we create the batch
    end
  end

end