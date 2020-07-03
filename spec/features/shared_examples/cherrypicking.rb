# frozen_string_literal: true

shared_examples 'a cherrypicking procedure' do
  attr_reader :batch_id
  attr_reader :batch_barcode

  it 'can run the cherrypicking pipeline' do
    step 'Setting up the batch' do
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

      step 'Task 1, Step 1 - Select layout options' do
        select(target_purpose.name, from: 'Output plate purpose')
        select(plate_template.name, from: 'Plate Template')

        # optionally select a control plate
        select(control_plate.human_barcode, from: 'Control plate') if control_plate
      end

      step 'Task 1, Step 2 - Select Robot' do
        select(robot.name, from: 'Picking Robot')
      end

      step 'Task 1, Step 3 - Specify volume to pick' do
        choose(layout_volume_option)

        case layout_volume_option
        when 'Pick by µl'
          fill_in('micro_litre_volume_required', with: '13')
        when 'Pick by ng/µl'
          fill_in('Volume Required', with: '65')
          within('#pick_by_nano_grams_per_micro_litre') do
            fill_in('Robot Minimum Picking Volume', with: '1.0')
          end
        when 'Pick by ng'
          within('#pick_by_nano_grams') do
            fill_in('Robot Minimum Picking Volume', with: '2.0')
            fill_in('Quantity to pick', with: 10000)
            fill_in('Minimum Volume', with: 20)
            fill_in('Maximum Volume', with: 150)
          end
        end

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

    step 'Printing the worksheets' do
      step 'Extract the batch identifier' do
        within('.page-header') do
          @batch_id = page.find('.subtitle').text
          @batch_barcode = Barcode.calculate_barcode('BA', batch_id)
        end
      end

      step 'Print and check the worksheet for each output destination plate' do
        expected_plates_by_destination_plate.each do |(destination_barcode, expected_plates)|
          step 'check the show plate screen' do
            visit batch_path(batch_id)

            within('#output_assets table tbody') do
              row = page.all('tr', text: /#{destination_barcode}/).first
              within(row) do
                click_link 'Show plate'
              end
            end

            destination_plate = Plate.find_by_barcode(destination_barcode)

            # check for source transfer into the destination
            # assumption that there is a cherrypick into the A1 in the destination
            transfer_request = destination_plate.wells.first.transfer_requests_as_target.first
            expect(page).to have_content(transfer_request.target_aliquots.first.sample.name)

            # check for control sample transfer into the destination if appropriate
            if control_plate
              expect(page).to have_content(control_plate.contained_samples.first.name)
            end
          end

          step 'check the worksheets' do
            visit batch_path(batch_id)

            within('#output_assets table tbody') do
              row = page.all('tr', text: /#{destination_barcode}/).first
              within(row) do
                click_link 'Print worksheet'
              end
            end

            expect(page).to have_content('This worksheet was generated')

            (1..expected_plates.size).each do |pick_number_index|
              within("#worksheet_plate_#{destination_barcode}_pick_#{pick_number_index}") do
                within('#source_plates') do
                  expected_plates[pick_number_index][:sources].each do |plate|
                    expect(page).to have_content(plate.human_barcode)
                  end
                end

                control_plate = expected_plates[pick_number_index][:control]
                if control_plate
                  within('#control_plates') do
                    expect(page).to have_content(control_plate.human_barcode)
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

                  # check that the number each cell contains is in the expected list of plate barcodes
                  # N.B. this doesn't actually check the correct picks are going to correct wells at sample level
                  cells_with_content.each do |cell|
                    barcode_numbers = expected_plates[pick_number_index][:sources].map(&:barcode_number)
                    barcode_numbers << control_plate.barcode_number if control_plate
                    number_in_cell = cell.text.split(' ')[1]

                    expect(barcode_numbers).to include(number_in_cell)
                  end
                end
              end
            end
          end
        end
      end
    end

    # rubocop:disable Metrics/BlockLength
    step 'Perform the bed verifications and check picking files' do
      expected_plates_by_destination_plate.each do |(destination_barcode, current_expected_plates)|
        (1..current_expected_plates.size).each do |pick_number_index|
          step "Setup bed verification for #{destination_barcode} pick number #{pick_number_index}" do
            step 'visit robot verifications page' do
              visit('/robot_verifications')
            end

            step 'scan user, and robot, worksheet and destination plate barcodes' do
              worksheet_barcode = "#{batch_barcode}-#{pick_number_index}"

              fill_in('Scan user ID', with: swipecard_code)
              fill_in('Scan robot', with: robot_barcode)
              fill_in('Scan worksheet', with: worksheet_barcode)
              fill_in('Scan destination plate', with: destination_barcode)

              click_on('Check')
            end
          end

          step 'Perform bed verification' do
            # need subset of plates for the current pick number
            current_source_plates = current_expected_plates[pick_number_index][:sources]
            control_plate = current_expected_plates[pick_number_index][:control]

            step 'scan beds' do
              # fill in robot bed barcodes for sources
              # NB. screen erb seems to override key in robot properties and adds the space e.g. SCRC 1 not SCRC1
              (1..current_source_plates.count).each do |i|
                fill_in("SCRC #{i}", with: SBCF::SangerBarcode.new(prefix: 'RB', number: i).machine_barcode)
              end

              # fill in robot bed barcode for control if present
              fill_in('CTRL 1', with: SBCF::SangerBarcode.new(prefix: 'RB', number: max_plates).machine_barcode) if control_plate

              # fill in robot bed barcode for destination
              fill_in('DEST 1', with: SBCF::SangerBarcode.new(prefix: 'RB', number: max_plates + 1).machine_barcode)
            end

            step 'scan plate barcodes' do
              # source plate barcodes
              current_source_plates.each do |plate|
                fill_in(plate.human_barcode, with: plate.human_barcode)
              end

              # control plate barcode
              fill_in(control_plate.human_barcode, with: control_plate.human_barcode) if control_plate

              # destination plate barcodes
              fill_in(destination_barcode, with: destination_barcode)
            end

            step 'optionally set custom destination plate type' do
              # optionally fill in custom plate type for the destination
              select(custom_destination_type_name, from: "plate_types[#{destination_barcode}]") if custom_destination_type
            end

            step 'verify bed layout' do
              click_on('Verify')
            end
          end

          step "Download pick file for destination plate #{destination_barcode} pick number #{pick_number_index}" do
            expect(page).to have_content("Download #{robot.name.capitalize} File Step 3 of 3")

            click_link("Download #{robot.name} File")

            # robot file generation differs by generator
            case robot.generation_behaviour_property.value
            when 'Hamilton'
              # for Robot::Generator::Hamilton
              generated_file = DownloadHelpers.downloaded_file("#{batch_id}_batch_#{destination_barcode}_#{pick_number_index}.csv")
              generated_lines = generated_file.lines

              # optionally if an expected file was supplied. compare it to the result
              if expected_pick_files_by_destination_plate.present?
                # fetch our expected file structure
                expected_file = expected_pick_files_by_destination_plate[destination_barcode][pick_number_index]
                expected_file_lines = expected_file.lines

                expect(generated_lines.length).to eq(expected_file_lines.length)
                expected_file_lines.each_with_index do |expected_line, index|
                  expect(generated_lines[index]).to eq(expected_line), "Error on line #{index} in #{expected_file}"
                end
              end
            when 'Tecan'
              # for Robot::Generator::Tecan
              generated_file = DownloadHelpers.downloaded_file("#{batch_id}_batch_#{destination_barcode}_#{pick_number_index}.gwl")
              generated_lines = generated_file.lines

              # optionally if an expected file was supplied. compare it to the result
              if expected_pick_files_by_destination_plate.present?
                # Shift off the dynamic comment lines
                generated_lines.shift(2)

                # fetch our expected file structure
                expected_file = expected_pick_files_by_destination_plate[destination_barcode][pick_number_index]
                expected_file_lines = expected_file.lines
                # Shift off the comment lines
                expected_file_lines.shift(2)

                expect(generated_lines.length).to eq(expected_file_lines.length)
                expected_file_lines.each_with_index do |expected_line, index|
                  # Shift the error line number
                  expect(generated_lines[index]).to eq(expected_line), "Error on line #{index + 2} in #{expected_file}"
                end
              end
            end
          end
        end
      end
    end
    # rubocop:enable Metrics/BlockLength
  end
end
