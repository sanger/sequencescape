# frozen_string_literal: true

require 'rails_helper'

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

  shared_examples_for 'a batch is created' do
    it 'can process the cherrypicking' do
      step 'Set up the batch' do
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
            expect(page).to have_selector('tr', count: expected_plates_by_destination_plate.size)
          end
        end
      end
    end
  end

  shared_examples_for 'a cherrypicking procedure' do
    attr_reader :batch_id
    attr_reader :batch_barcode

    it 'can process the cherrypicking' do
      step 'Set up the batch' do
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
            expect(page).to have_selector('tr', count: expected_plates_by_destination_plate.size)
          end
        end
      end

      step 'Print the worksheets' do
        within('.page-header') do
          @batch_id = page.find('.subtitle').text
          @batch_barcode = Barcode.calculate_barcode('BA', batch_id)
        end

        expected_plates_by_destination_plate.each_with_index do |(destination_barcode, current_expected_plates), destination_index|
          visit batch_path(batch_id)

          within('#output_assets table tbody') do
            rows = page.all('tr')
            rows.each { |row| puts "DEBUG: row: #{row.value}" }
            rows.each { |row| puts "DEBUG: row: #{row.text}" }
            within(rows[destination_index]) do
              click_link 'Print worksheet'
            end
          end

          expect(page).to have_content('This worksheet was generated')

          (1..current_expected_plates.size).each do |pick_number_index|
            within("#worksheet_plate_#{destination_barcode}_pick_#{pick_number_index}") do
              within('#source_plates') do
                current_expected_plates[pick_number_index].each do |plate|
                  expect(page).to have_content(plate.human_barcode)
                end
              end

              within('#destination_plate') do
                expect(page).to have_content(destination_barcode)
              end

              # check barcode
              within("#batchbarcode_#{destination_barcode}-#{pick_number_index}") do
                expect(page).to have_content("#{batch_barcode}-#{pick_number_index}")
              end

              # check wells
              within('#plate_layouts') do
                cells_with_content = page.all('td', text: /.+v13.0 b0.0/)

                # check that the number each cell contains is in the expected list of source plate barcodes
                cells_with_content.each do |cell|
                  barcode_numbers = current_expected_plates[pick_number_index].map(&:barcode_number)
                  puts "DEBUG: cell.text = #{cell.text}"
                  number_in_cell = cell.text.split(' ')[1]

                  expect(barcode_numbers).to include(number_in_cell)
                end
              end
            end
          end
        end
      end

      step 'Perform the bed verifications' do
        expected_plates_by_destination_plate.each_with_index do |(destination_barcode, current_expected_plates), _destination_index|
          (1..current_expected_plates.size).each do |pick_number_index|
            step 'visit robot verifications page' do
              visit('/robot_verifications')
            end

            step 'scan user id' do
              fill_in('Scan user ID', with: swipecard_code)
            end

            step 'scan robot barcode' do
              fill_in('Scan robot', with: robot_barcode)
            end

            step 'scan worksheet' do
              worksheet_barcode = "#{batch_barcode}-#{pick_number_index}"
              fill_in('Scan worksheet', with: worksheet_barcode)
            end

            step 'scan destination plate' do
              fill_in('Scan destination plate', with: destination_barcode)
              click_on('Check')
            end

            step 'perform bed verification' do
              # need subset of plates for the current pick number
              current_plates = current_expected_plates[pick_number_index]

              # fill in robot beds
              (1..current_plates.count).each do |i|
                fill_in("SCRC #{i}", with: SBCF::SangerBarcode.new(prefix: 'RB', number: i).machine_barcode)
              end
              fill_in('DEST 1', with: SBCF::SangerBarcode.new(prefix: 'RB', number: max_plates + 1).machine_barcode)

              # fill in plate barcodes
              current_plates.each do |plate|
                fill_in(plate.human_barcode, with: plate.human_barcode)
              end
              fill_in(destination_barcode, with: destination_barcode)

              click_on('Verify')
              expect(page).to have_content("Download #{robot.name.capitalize} File Step 3 of 3")
            end
          end
        end
      end
    end
  end

  # describe 'where the number of plates doesnt exceed the max beds for the robot' do
  #   attr_reader :batch_id
  #   attr_reader :batch_barcode

  #   let(:max_plates) { 17 }
  #   let(:plates) { create_list(:plate_with_untagged_wells_and_custom_name, 3, sample_count: 2) }
  #   let(:expected_plates_by_destination_plate) do
  #     {
  #       destination_plate_human_barcode => {
  #         1 => [plates[0], plates[1], plates[2]]
  #       }
  #     }
  #   end

  #   it 'whole thing' do
  #     step 'a batch is created' do
  #       it_behaves_like 'a batch is created'
  #     end
  #   end

  #   # RSpec::Steps.steps 'perform cherrypicking processes' do
  #   #   it_behaves_like 'a batch is created'

  #   #   # it_behaves_like 'worksheets can be printed'

  #   #   # it_behaves_like 'beds can be verified'

  #   #   # it_behaves_like 'picking files can be printed'
  #   # end
  # end

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
