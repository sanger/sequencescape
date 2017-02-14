# frozen_string_literal: true
require 'rails_helper'
require 'pry'

feature 'cherrypick pipeline - nano grams per micro litre', js: true do
  let(:user) { create :admin, barcode: 'ID41440E' }
  let(:project) { create :project, name: 'Test project' }
  let(:study) { create :study }
  let(:location) { Location.find_by(name: 'Sample logistics freezer') }
  let(:pipeline_name) { 'Cherrypick' }
  let(:pipeline) { Pipeline.find_by(name: pipeline_name) }
  let(:plate1) { create :plate_with_untagged_wells, well_order: :row_order, sample_count: 2, barcode: '1', location: location }
  let(:plate2) { create :plate_with_untagged_wells, well_order: :row_order, sample_count: 2, barcode: '10', location: location }
  let(:plate3) { create :plate_with_untagged_wells, well_order: :row_order, sample_count: 2, barcode: '5', location: location }
  let(:plates) { [plate1, plate2, plate3] }
  let(:submission_template) { SubmissionTemplate.find_by(name: pipeline_name) }
  let(:workflow) { Submission::Workflow.find_by(key: 'microarray_genotyping') }
  let(:barcode) { 99999 }
  let(:robot) { create :robot, barcode: '444' }
  let!(:plate_template) { create :plate_template }

  before(:each) do
    assets = plates.each_with_object([]) do |plate, assets|
      assets.concat(plate.wells)
      plate.wells.each_with_index do |well, index|
        well.well_attribute.update_attributes!(
          current_volume: 30 + (index % 30),
          concentration: 205 + (index % 50)
        )
      end
    end
    submission = submission_template.create_and_build_submission!(
      study: study,
      project: project,
      workflow: workflow,
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

  # from 6628187_tests_for_fix_tecan_volumes.feature
  # Feature: The Tecan file has the wrong buffer volumes, defaulting to 13 total volume
  scenario 'required volume is 65' do
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
    fill_in('nano_grams_per_micro_litre_volume_required', with: '65')
    fill_in('nano_grams_per_micro_litre_robot_minimum_picking_volume', with: '1.0')
    click_button 'Next step'
    click_button 'Next step'
    select('Genotyping freezer', from: 'Location')
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_content('Batch released!')

    batch = Batch.last
    batch.update_attributes!(barcode: Barcode.number_to_human(550000555760))

    visit robot_verifications_path
    fill_in('Scan user ID', with: '2470041440697')
    fill_in('Scan Tecan robot', with: '4880000444853')
    fill_in('Scan worksheet', with: '550000555760')
    fill_in('Scan destination plate', with: '1220099999705')
    click_button 'Check'
    expect(page).to have_content('Scan robot beds and plates')

    table = [['Bed', 'Scanned robot beds', 'Plate ID', 'Scanned plates', 'Plate type'],
             ['SCRC 1', '', '1220000001831', '', 'ABgene_0765 ABgene_0800 FluidX075'],
             ['SCRC 2', '', '1220000010734', '', 'ABgene_0765 ABgene_0800 FluidX075'],
             ['SCRC 3', '', '1220000005877', '', 'ABgene_0765 ABgene_0800 FluidX075'],
             ['DEST 1', '', '1220099999705', '', 'ABgene_0800']]
    expect(fetch_table('table#source_beds')).to eq(table)

    fill_in('SCRC 1', with: '4880000001780')
    fill_in('1220000001831', with: '1220000001831')
    fill_in('SCRC 2', with: '4880000002794')
    fill_in('1220000005877', with: '1220000005877')
    fill_in('SCRC 3', with: '4880000003807')
    fill_in('1220000010734', with: '1220000010734')
    fill_in('DEST 1', with: '4880000020729')
    fill_in('1220099999705', with: '1220099999705')

    click_button 'Verify'
    expect(page).to have_content('Download TECAN file')

    plate = Plate.find_from_machine_barcode('1220099999705')
    generated_file = batch.tecan_gwl_file_as_text(plate.barcode, batch.total_volume_to_cherrypick, 'ABgene 0765')
    generated_lines = generated_file.split(/\n/)
    generated_lines.shift(2)
    expect(generated_lines).to be_truthy
    tecan_file =
      "C;
      A;BUFF;;96-TROUGH;1;;49.1
      D;1220099999705;;ABgene 0800;1;;49.1
      W;
      A;BUFF;;96-TROUGH;2;;49.2
      D;1220099999705;;ABgene 0800;2;;49.2
      W;
      A;BUFF;;96-TROUGH;3;;49.1
      D;1220099999705;;ABgene 0800;3;;49.1
      W;
      A;BUFF;;96-TROUGH;4;;49.2
      D;1220099999705;;ABgene 0800;4;;49.2
      W;
      A;BUFF;;96-TROUGH;5;;49.1
      D;1220099999705;;ABgene 0800;5;;49.1
      W;
      A;BUFF;;96-TROUGH;6;;49.2
      D;1220099999705;;ABgene 0800;6;;49.2
      W;
      C;
      A;1220000001831;;ABgene 0765;1;;15.9
      D;1220099999705;;ABgene 0800;1;;15.9
      W;
      A;1220000001831;;ABgene 0765;9;;15.8
      D;1220099999705;;ABgene 0800;2;;15.8
      W;
      A;1220000010734;;ABgene 0765;1;;15.9
      D;1220099999705;;ABgene 0800;3;;15.9
      W;
      A;1220000010734;;ABgene 0765;9;;15.8
      D;1220099999705;;ABgene 0800;4;;15.8
      W;
      A;1220000005877;;ABgene 0765;1;;15.9
      D;1220099999705;;ABgene 0800;5;;15.9
      W;
      A;1220000005877;;ABgene 0765;9;;15.8
      D;1220099999705;;ABgene 0800;6;;15.8
      W;
      C;
      C; SCRC1 = 1220000001831
      C; SCRC2 = 1220000010734
      C; SCRC3 = 1220000005877
      C;
      C; DEST1 = 1220099999705"

    tecan_file_lines = tecan_file.lines.map(&:strip)

    generated_lines.each_with_index do |generated_line, index|
      if defined?(JRuby)
        expect(generated_line).to eq(tecan_file_lines[index])
      else
        # MRI and Jruby have different float rounding behaviour
        # Both are valid, here we relax constraints for MRI.
        # The relaxed constraints are a little more permissive than
        # would be ideal.
        compare_lines_in_mri(tecan_file_lines[index], generated_line)
      end
    end
  end

  def fetch_table(selector)
    find(selector).all('tr').map { |row| row.all('th,td').map { |cell| cell.text.squish } }
  end

  def compare_lines_in_mri(tecan_file_line, generated_line)
    _expect_line, expect_root, expect_round = /(.*)(\.\d)/.match(tecan_file_line)
    _actual_line, actual_root, actual_round = /(.*)(\.\d)/.match(generated_line)
    expect(expect_root).to eq(actual_root)
    valid_end = (expect_round == actual_round) || # The rounded digets match
      (expect_round.to_i - actual_round.to_i == 1) && (actual_round.to_i.even?) # The digit has been rounded down to even
    expect(valid_end).to be true
  end
end
