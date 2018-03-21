# frozen_string_literal: true

require 'rails_helper'
require 'pry'

feature 'cherrypick for fluidigm pipeline - micro litre', js: true do
  let(:user) { create :admin }
  let(:project) { create :project, name: 'Test project' }
  let(:study) { create :study }
  let(:pipeline_name) { 'Cherrypick for Fluidigm' }
  let(:pipeline) { Pipeline.find_by(name: pipeline_name) }
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
          measured_volume: 30 + (index % 30)
        )
      end
    end
    submission_template_hash = {
      name: 'Cherrypick for Fluidigm',
      submission_class_name: 'LinearSubmission',
      product_catalogue: 'Generic',
      submission_parameters: { info_differential: 6,
                               request_types: %w[pick_to_sta pick_to_sta2 pick_to_snp_type pick_to_fluidigm] }
    }
    submission_template = SubmissionSerializer.construct!(submission_template_hash)
    submission = submission_template.create_and_build_submission!(
      study: study,
      project: project,
      user: user,
      assets: assets,
      request_options: { target_purpose_name: 'Fluidigm 96-96' }
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

  scenario 'required volume is 13' do
    login_user(user)
    visit pipeline_path(pipeline)
    first(:button, 'Select all').click
    find_all(:checkbox).each do |checkbox|
      expect(checkbox).to be_checked
    end
    first(:button, 'Deselect all').click
    find_all(:checkbox).each do |checkbox|
      expect(checkbox).to_not be_checked
    end
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select('testtemplate', from: 'Plate Template')
    fill_in('micro_litre_volume_required', with: '13')
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')
  end
end
