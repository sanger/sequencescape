# frozen_string_literal: true

require 'rails_helper'
require './spec/features/shared_examples/cherrypicking'

describe 'Cherrypicking pipeline', type: :feature, cherrypicking: true, js: true do
  include RSpec::Longrun::DSL
  include BarcodeHelper

  let(:swipecard_code) { '123456' }
  let(:user) { create :admin, swipecard_code: swipecard_code }
  let(:project) { create :project }
  let(:study) { create :study }
  let(:pipeline) { create :cherrypick_pipeline }
  let(:pipeline_name) { pipeline.name }
  let(:max_plates) { 17 }
  let!(:robot) do
    create(:full_robot, barcode: '1111', number_of_sources: max_plates,
                        number_of_destinations: 1, max_plates_value: max_plates)
  end
  let(:robot_barcode) { SBCF::SangerBarcode.new(prefix: 'RB', number: robot.barcode).machine_barcode }
  let(:submission) { create :submission }
  let!(:plate_template) { create :plate_template }
  let!(:plate_type) { create :plate_type, name: 'ABgene_0765', maximum_volume: 800 }
  let(:destination_plate_barcode) { '1001' }
  let(:destination_plate_human_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode).human_barcode }
  let!(:target_purpose) { create :plate_purpose }
  let!(:control_plate) { nil }
  let(:concentrations_required) { false }
  let!(:custom_destination_type) { nil }
  let(:custom_destination_type_name) { custom_destination_type.name || nil }
  let(:expected_pick_files_by_destination_plate) { nil }
  let!(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, 3, sample_count: 2) }

  before do
    plates.each do |plate|
      plate.wells.each_with_index do |well, index|
        # create the requests for cherrypicking
        create :cherrypick_request,
               asset: well,
               request_type: pipeline.request_types.first,
               submission: submission,
               study: study,
               project: project

        # create a concentration value on the wells if required
        next unless concentrations_required

        well.well_attribute.update!(
          measured_volume: 30 + (index % 30),
          current_volume: 30 + (index % 30),
          concentration: 205 + (index % 50)
        )
      end
    end

    mock_plate_barcode_service
  end

  describe 'when creating batches' do
    it 'requests leave the inbox once a batch has been created' do
      login_user(user)
      visit pipeline_path(pipeline)
      expect(page).to have_content("Pipeline #{pipeline_name}")
      expect(page).to have_content(plates[0].human_barcode)
      check("Select #{plates[0].human_barcode} for batch")
      check("Select #{plates[2].human_barcode} for batch")
      check("Select #{plates[1].human_barcode} for batch")
      first(:select, 'action_on_requests').select('Create Batch')
      first(:button, 'Submit').click
      click_link 'Back to pipeline'
      expect(page).not_to have_content(plates[0].human_barcode)
    end
  end

  describe 'where picking by ng/µl for a tecan robot' do
    let(:concentrations_required) { true }
    let(:layout_volume_option) { 'Pick by ng/µl' }
    let!(:custom_destination_type) { create :plate_type, name: 'Custom Type' }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => { sources: [plates[0], plates[1], plates[2]] }
        }
      }
    end
    let(:expected_tecan_file) do
      <<~TECAN
        C;
        C; This file created by user_abc6 on 2018-06-14 11:17:04 +0100
        C;
        A;BUFF;;96-TROUGH;1;;49.1
        D;#{destination_plate_human_barcode};;Custom Type;1;;49.1
        W;
        A;BUFF;;96-TROUGH;2;;49.2
        D;#{destination_plate_human_barcode};;Custom Type;2;;49.2
        W;
        A;BUFF;;96-TROUGH;3;;49.1
        D;#{destination_plate_human_barcode};;Custom Type;3;;49.1
        W;
        A;BUFF;;96-TROUGH;4;;49.2
        D;#{destination_plate_human_barcode};;Custom Type;4;;49.2
        W;
        A;BUFF;;96-TROUGH;5;;49.1
        D;#{destination_plate_human_barcode};;Custom Type;5;;49.1
        W;
        A;BUFF;;96-TROUGH;6;;49.2
        D;#{destination_plate_human_barcode};;Custom Type;6;;49.2
        W;
        C;
        A;#{plates[0].human_barcode};;ABgene 0765;1;;15.9
        D;#{destination_plate_human_barcode};;Custom Type;1;;15.9
        W;
        A;#{plates[0].human_barcode};;ABgene 0765;2;;15.8
        D;#{destination_plate_human_barcode};;Custom Type;2;;15.8
        W;
        A;#{plates[1].human_barcode};;ABgene 0765;1;;15.9
        D;#{destination_plate_human_barcode};;Custom Type;3;;15.9
        W;
        A;#{plates[1].human_barcode};;ABgene 0765;2;;15.8
        D;#{destination_plate_human_barcode};;Custom Type;4;;15.8
        W;
        A;#{plates[2].human_barcode};;ABgene 0765;1;;15.9
        D;#{destination_plate_human_barcode};;Custom Type;5;;15.9
        W;
        A;#{plates[2].human_barcode};;ABgene 0765;2;;15.8
        D;#{destination_plate_human_barcode};;Custom Type;6;;15.8
        W;
        C;
        C; SCRC1 = #{plates[0].human_barcode}
        C; SCRC2 = #{plates[1].human_barcode}
        C; SCRC3 = #{plates[2].human_barcode}
        C;
        C; DEST1 = DN1001S
      TECAN
    end
    let(:expected_pick_files_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => expected_tecan_file
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where picking by ng for a tecan robot' do
    let(:concentrations_required) { true }
    let(:layout_volume_option) { 'Pick by ng' }
    let!(:plate_type) { create :plate_type, name: 'ABgene_0800', maximum_volume: 800 }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => { sources: [plates[0], plates[1], plates[2]] }
        }
      }
    end
    let(:expected_tecan_file) do
      <<~TECAN
        C;
        C; This file created by user_abc12 on 2018-06-14 17:09:13 +0100
        C;
        A;#{plates[0].human_barcode};;ABgene 0800;1;;30.0
        D;#{destination_plate_human_barcode};;ABgene 0800;1;;30.0
        W;
        A;#{plates[0].human_barcode};;ABgene 0800;2;;31.0
        D;#{destination_plate_human_barcode};;ABgene 0800;2;;31.0
        W;
        A;#{plates[1].human_barcode};;ABgene 0800;1;;30.0
        D;#{destination_plate_human_barcode};;ABgene 0800;3;;30.0
        W;
        A;#{plates[1].human_barcode};;ABgene 0800;2;;31.0
        D;#{destination_plate_human_barcode};;ABgene 0800;4;;31.0
        W;
        A;#{plates[2].human_barcode};;ABgene 0800;1;;30.0
        D;#{destination_plate_human_barcode};;ABgene 0800;5;;30.0
        W;
        A;#{plates[2].human_barcode};;ABgene 0800;2;;31.0
        D;#{destination_plate_human_barcode};;ABgene 0800;6;;31.0
        W;
        C;
        C; SCRC1 = #{plates[0].human_barcode}
        C; SCRC2 = #{plates[1].human_barcode}
        C; SCRC3 = #{plates[2].human_barcode}
        C;
        C; DEST1 = #{destination_plate_human_barcode}
      TECAN
    end
    let(:expected_pick_files_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => expected_tecan_file
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where the number of plates does not exceed the max beds for the robot' do
    let(:layout_volume_option) { 'Pick by µl' }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => { sources: [plates[0], plates[1], plates[2]] }
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where the number of plates exceeds the max beds for the robot' do
    let(:layout_volume_option) { 'Pick by µl' }
    let(:max_plates) { 2 }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => { sources: [plates[0], plates[1]] },
          2 => { sources: [plates[2]] }
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where there are multiple destination plates and the number of plates exceeds the max beds for the robot' do
    let(:layout_volume_option) { 'Pick by µl' }
    let(:max_plates) { 2 }
    let(:full_plate) { create(:plate_with_untagged_wells_and_custom_name, sample_count: 96) }
    let(:additional_plates) { create_list(:plate_with_untagged_wells_and_custom_name, 3, sample_count: 2) }
    let!(:plates) { additional_plates << full_plate }

    let(:destination_plate_barcode_2) { '1002' }
    let(:destination_plate_human_barcode_2) { SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode_2).human_barcode }

    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => { sources: [plates[0], plates[1]] },
          2 => { sources: [plates[2], plates[3]] }
        },
        destination_plate_human_barcode_2 => {
          1 => { sources: [plates[3]] }
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where there is a control plate' do
    let(:plate1) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '1' }
    let(:plate2) { create  :plate_with_untagged_wells, sample_count: 2, barcode: '10' }
    let(:plate3) { create  :control_plate, sample_count: 2, barcode: '5' }
    let(:plates) { [plate1, plate2, plate3] }
    # TODO: robot factory should use max_plates value passed in
    let(:max_plates) { 25 }
    let!(:robot) { create :hamilton, barcode: '444' }
    let(:concentrations_required) { true }
    let(:layout_volume_option) { 'Pick by ng/µl' }
    let!(:custom_destination_type) { create :plate_type, name: 'Custom Type' }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => { sources: [plates[0], plates[1]], control: plates[2] }
        }
      }
    end
    let(:expected_hamilton_file) do
      <<~FILE
        SourcePlateID,SourceWellID,SourcePlateType,SourcePlateVolume,DestinationPlateID,DestinationWellID,DestinationPlateType,DestinationPlateVolume,WaterVolume
        #{plates[0].human_barcode},A1,ABgene 0765,15.85,#{destination_plate_human_barcode},A1,Custom Type,15.85,49.15
        #{plates[0].human_barcode},B1,ABgene 0765,15.78,#{destination_plate_human_barcode},B1,Custom Type,15.78,49.22
        #{plates[1].human_barcode},A1,ABgene 0765,15.85,#{destination_plate_human_barcode},C1,Custom Type,15.85,49.15
        #{plates[1].human_barcode},B1,ABgene 0765,15.78,#{destination_plate_human_barcode},D1,Custom Type,15.78,49.22
        #{plates[2].human_barcode},A1,ABgene 0765,15.85,#{destination_plate_human_barcode},E1,Custom Type,15.85,49.15
        #{plates[2].human_barcode},B1,ABgene 0765,15.78,#{destination_plate_human_barcode},F1,Custom Type,15.78,49.22
      FILE
    end
    let(:expected_pick_files_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => expected_hamilton_file
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end
end
