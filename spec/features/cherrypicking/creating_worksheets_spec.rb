# frozen_string_literal: true

require 'rails_helper'
require './spec/features/shared_examples/cherrypicking'

describe 'Creating worksheets', type: :feature, cherrypicking: true, js: true do
  include RSpec::Longrun::DSL
  include BarcodeHelper

  let(:swipecard_code) { '123456' }
  let(:user) { create :admin, swipecard_code: swipecard_code }
  let(:project) { create :project }
  let(:study) { create :study }
  let(:pipeline) { create :cherrypick_pipeline }
  let(:max_plates) { 17 }
  let!(:robot) do
    create(
      :full_robot,
      barcode: '1111',
      number_of_sources: max_plates,
      number_of_destinations: 1,
      robot_properties: [create(:robot_property, name: 'maxplates', key: 'max_plates', value: max_plates)]
    )
  end
  let(:robot_barcode) { SBCF::SangerBarcode.new(prefix: 'RB', number: robot.barcode).machine_barcode }
  let(:submission) { create :submission }
  let!(:plate_template) { create :plate_template }
  let!(:plate_type) { create :plate_type }
  let(:destination_plate_barcode) { '1001' }
  let(:destination_plate_human_barcode) { SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode).human_barcode }

  before do
    plates.each do |plate|
      plate.wells.each do |well|
        create :cherrypick_request, asset: well, request_type: pipeline.request_types.first, submission: submission, study: study, project: project
      end
    end

    mock_plate_barcode_service
  end

  describe 'where the number of plates doesnt exceed the max beds for the robot' do
    let(:max_plates) { 17 }
    let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, 3, sample_count: 2) }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => [plates[0], plates[1], plates[2]]
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where the number of plates exceeds the max beds for the robot' do
    let(:max_plates) { 2 }
    let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, 3, sample_count: 2) }
    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => [plates[0], plates[1]],
          2 => [plates[2]]
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end

  describe 'where there are multiple destination plates and the number of plates exceeds the max beds for the robot' do
    let(:max_plates) { 2 }
    let(:full_plate) { create(:plate_with_untagged_wells_and_custom_name, sample_count: 96) }
    let(:additional_plates) { create_list(:plate_with_untagged_wells_and_custom_name, 3, sample_count: 2) }
    let(:plates) { additional_plates << full_plate }

    let(:destination_plate_barcode_2) { '1002' }
    let(:destination_plate_human_barcode_2) { SBCF::SangerBarcode.new(prefix: 'DN', number: destination_plate_barcode_2).human_barcode }

    let(:expected_plates_by_destination_plate) do
      {
        destination_plate_human_barcode => {
          1 => [plates[0], plates[1]],
          2 => [plates[2], plates[3]]
        },
        destination_plate_human_barcode_2 => {
          1 => [plates[3]]
        }
      }
    end

    it_behaves_like 'a cherrypicking procedure'
  end
end
