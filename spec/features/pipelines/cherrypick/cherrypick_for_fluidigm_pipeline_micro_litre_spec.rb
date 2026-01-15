# frozen_string_literal: true

require 'rails_helper'
require 'pry'

describe 'cherrypick for fluidigm pipeline - micro litre', :js do
  let(:user) { create(:admin) }
  let(:project) { create(:project, name: 'Test project') }
  let(:study) { create(:study) }
  let(:pipeline_name) { pipeline.name }
  let(:pipeline) { create(:fluidigm_pipeline) }
  let(:submission) { create(:submission) }
  let(:plate1) { create(:plate_with_untagged_wells, sample_count: 2, barcode: 'SQPD-1') }
  let(:plate2) { create(:plate_with_untagged_wells, sample_count: 2, barcode: 'SQPD-10') }
  let(:plate3) { create(:plate_with_untagged_wells, sample_count: 2, barcode: 'SQPD-5') }
  let(:plates) { [plate1, plate2, plate3] }
  let(:robot) { create(:robot, barcode: '444') }
  let!(:plate_template) { create(:plate_template) }
  let(:request_types) { pipeline.request_types.map(&:key) }

  before do
    target_purpose = create(:plate_purpose, name: 'Fluidigm')
    assets =
      plates.each_with_object([]) do |plate, assets|
        assets.concat(plate.wells)
        plate.wells.each_with_index { |well, index| well.well_attribute.update!(measured_volume: 30 + (index % 30)) }
      end
    assets.each do |asset|
      create(
        :cherrypick_for_fluidigm_request,
        asset: asset,
        request_type: pipeline.request_types.first,
        submission: submission,
        study: study,
        project: project,
        target_purpose: target_purpose
      )
    end

    allow(PlateBarcode).to receive(:create_barcode).and_return(build(:plate_barcode, barcode: 'SQPD-2'))

    robot.robot_properties.create(key: 'max_plates', value: '21')
    robot.robot_properties.create(key: 'SCRC1', value: '1')
    robot.robot_properties.create(key: 'SCRC2', value: '2')
    robot.robot_properties.create(key: 'SCRC3', value: '3')
    robot.robot_properties.create(key: 'DEST1', value: '20')
  end

  it 'required volume is 13' do
    login_user(user)
    visit pipeline_path(pipeline)
    first(:button, 'Select all').click
    find_all(:checkbox).each { |checkbox| expect(checkbox).to be_checked }
    first(:button, 'Deselect all').click
    find_all(:checkbox).each { |checkbox| expect(checkbox).not_to be_checked }

    check('Select SQPD-1 for batch')
    check('Select SQPD-10 for batch')
    check('Select SQPD-5 for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select('test_plate_template', from: 'Plate Template')
    fill_in('Volume to pick (µl)', with: 13)
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')
  end
end
