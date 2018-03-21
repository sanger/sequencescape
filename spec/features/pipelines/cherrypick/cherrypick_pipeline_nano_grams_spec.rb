# frozen_string_literal: true

require 'rails_helper'
require 'pry'

feature 'cherrypick pipeline - nano grams', js: true do
  let(:user) { create :admin }
  let(:project) { create :project, name: 'Test project' }
  let(:study) { create :study }
  let(:pipeline_name) { 'Cherrypick' }
  let(:pipeline) { Pipeline.find_by!(name: pipeline_name) }
  let(:plate1) { create :plate_with_untagged_wells, sample_count: 2, barcode: '1' }
  let(:plate2) { create :plate_with_untagged_wells, sample_count: 2, barcode: '10' }
  let(:plate3) { create :plate_with_untagged_wells, sample_count: 2, barcode: '5' }
  let(:plates) { [plate1, plate2, plate3] }
  let(:barcode) { 99999 }
  let(:robot) { create :robot, barcode: '444' }
  let!(:plate_template) { create :plate_template }

  before(:each) do
    assets = plates.each_with_object([]) do |plate, assets|
      assets.concat(plate.wells)
      plate.wells.each_with_index do |well, index|
        well.well_attribute.update_attributes!(
          current_volume: 30 + (index % 30),
          concentration: 205 + (index % 50),
          measured_volume: 30 + (index % 30)
        )
      end
    end
    submission_template_hash = {
      name: 'Cherrypick',
      submission_class_name: 'LinearSubmission',
      product_catalogue: 'Generic',
      submission_parameters: { info_differential: 6,
                               asset_input_methods: ['select an asset group', 'enter a list of sample names found on plates'],
                               request_types: ['cherrypick'] }
    }
    submission_template = SubmissionSerializer.construct!(submission_template_hash)
    submission = submission_template.create_and_build_submission!(
      study: study,
      project: project,
      user: user,
      assets: assets
    )
    Delayed::Worker.new.work_off

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

  scenario 'robot minimum picking volume is 2.0' do
    login_user(user)
    visit pipeline_path(pipeline)
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select('testtemplate', from: 'Plate Template')
    select('Infinium 670k', from: 'Output plate purpose')
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
