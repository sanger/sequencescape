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
# select pick by ul
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
  let(:robot) { create(:robot) do |robot|
    robot.robot_properties << RobotProperties.create(key: 'max_plates', value: 17)
  end }
  let(:submission) { create :submission }  

  describe 'where the number of plates doesnt exceed the max beds for the robot' do

    it 'has a max beds property' do
      p robot.max_beds
      expect(robot.max_beds).to be_present
    end
  end

end