# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'cherrypick pipeline - micro litre', js: true do
  let(:user) { create :admin }
  let(:project) { create :project, name: 'Test project' }
  let(:study) { create :study }
  let(:location) { Location.find_by(name: 'Sample logistics freezer') }
  let(:pipeline_name) { 'Cherrypick' }
  let(:pipeline) { Pipeline.find_by(name: pipeline_name) }
  let(:plate1) { create :plate, barcode: '1', location: location }
  let(:plate2) { create :plate, barcode: '10', location: location }
  let(:plate3) { create :plate, barcode: '5', location: location }
  let(:asset_group) { create :asset_group, study: study }
  let(:plates) { [plate1, plate2, plate3] }
  let(:submission_template) { SubmissionTemplate.find_by(name: pipeline_name) }
  let(:workflow) { Submission::Workflow.find_by(key: 'microarray_genotyping') }
  let(:barcode) { 99999 }
  let(:robot) { create :robot, barcode: '444' }
  let!(:plate_template) { create :plate_template }

  before(:each) do
    plates.each do |plate|
      asset_group.assets << (1..2).map do |index|
        create(:well, plate: plate, map_id: index).tap do |well|
          well.aliquots.create!(sample: create(:sample, name: "Sample_#{plate.barcode}_#{index}"), study: study)
        end
      end
      plate.wells.each_with_index do |well, index|
        well.well_attribute.update_attributes!(
          measured_volume: 30 + (index % 30)
        )
      end
    end
    submission = submission_template.create_and_build_submission!(
      study: study,
      project: project,
      workflow: workflow,
      user: user,
      assets: asset_group.assets
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
    check('Select DN1S for batch')
    check('Select DN10I for batch')
    check('Select DN5W for batch')
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click
    click_link 'Select Plate Template'
    select('testtemplate', from: 'Plate Template')
    select('Infinium 670k', from: 'Output plate purpose')
    choose('cherrypick_action_micro_litre')
    fill_in('micro_litre_volume_required', with: '13')
    click_button 'Next step'
    click_button 'Next step'
    select('Genotyping freezer', from: 'Location')
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')
  end

  def login_user(user)
    visit login_path
    fill_in 'Username', with: user.login
    fill_in 'Password', with: 'password'
    click_button 'Login'
    true
  end
end
