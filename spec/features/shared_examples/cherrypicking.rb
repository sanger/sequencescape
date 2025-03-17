# frozen_string_literal: true

shared_examples 'a cherrypicking procedure' do
  attr_reader :batch_id
  attr_reader :batch_barcode

  it 'running the cherrypicking pipeline' do
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
        if control_plate
          placement_type = control_plate.custom_metadatum_collection&.metadata&.[]('control_placement_type')
          control_plate_text = "#{control_plate.human_barcode} - #{control_plate.name} (#{placement_type.capitalize})"
          select(control_plate_text, from: 'Control plate & placement type')
        end
      end

      step 'Task 1, Step 2 - Select Robot' do
        select(robot.name, from: 'Picking Robot')
      end

      step 'Task 1, Step 3 - Specify volume to pick' do
        choose(layout_volume_option)

        case layout_volume_option
        when 'Pick by volume (µl)'
          within('#pick_by_micro_litre') { fill_in('Volume (µl)', with: 13) }
        when 'Pick by concentration (ng/µl)'
          within('#pick_by_nano_grams_per_micro_litre') do
            fill_in('Volume Required (µl)', with: 65)
            fill_in('Robot Minimum Picking Volume', with: '1.0')
          end
        when 'Pick by amount (ng)'
          within('#pick_by_nano_grams') do
            fill_in('Robot Minimum Picking Volume', with: '2.0')
            fill_in('Quantity to pick', with: 10_000)
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
        expected_input_count = plates.count
        expected_input_count += 1 if control_plate
        within('#input_assets table tbody') { expect(page).to have_css('tr', count: expected_input_count) }
        within('#output_assets table tbody') do
          expect(page).to have_css('tr', count: expected_plates_by_destination_plate.size)
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
              row = page.find('tr', text: /#{destination_barcode}/)
              within(row) { click_link 'Show plate' }
            end

            destination_plate = Plate.find_by_barcode(destination_barcode)

            # check for source transfer into the destination
            # assumption that there is a cherrypick into the A1 in the destination
            transfer_request = destination_plate.wells.first.transfer_requests_as_target.first
            expect(page).to have_content(transfer_request.target_aliquots.first.sample.name)

            # check for control sample transfer into the destination if appropriate
            expect(page).to have_content(control_plate.contained_samples.first.name) if control_plate
          end

          step 'check the worksheets' do
            step 'visit the page' do
              visit batch_path(batch_id)
            end

            step 'get the file' do
              within('#output_assets table tbody') do
                row = page.all('tr', text: /#{destination_barcode}/).first
                within(row) { click_link 'Print worksheet' }
              end

              expect(page).to have_content('This worksheet was generated')
            end
            (1..expected_plates.size).each do |pick_number_index|
              within("#worksheet_plate_#{destination_barcode}_pick_#{pick_number_index}") do
                within('#source_plates') do
                  expected_plates[pick_number_index][:sources].each do |plate|
                    expect(page).to have_content(plate.human_barcode)
                  end
                end

                control_plate = expected_plates[pick_number_index][:control]
                within('#control_plates') { expect(page).to have_content(control_plate.human_barcode) } if control_plate
                within('#destination_plate') { expect(page).to have_content(destination_barcode) }

                # check barcode
                within('svg.barcode') { expect(page).to have_content("#{batch_barcode}-#{pick_number_index}") }

                # check wells
                within('#plate_layouts') do
                  cells_with_content = page.all('td', text: /.+v[\d.]+ b[\d.]+/, wait: 0)
                  expect(cells_with_content).not_to be_empty
                  barcode_numbers = expected_plates[pick_number_index][:sources].map(&:barcode_number)
                  barcode_numbers << control_plate.barcode_number if control_plate

                  # check that the number each cell contains is in the expected list of plate barcodes
                  # N.B. this doesn't actually check the correct picks are going to correct wells at sample level
                  cells_with_content.each do |cell|
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

    step 'Perform the bed verifications and check picking files' do
      # for each destination plate...
      expected_plates_by_destination_plate.each do |(destination_barcode, current_expected_plates)|
        # for each pick...
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

          def get_machine_barcode_for_bed(bedcode)
            num_barcode = robot.robot_properties.where(key: bedcode).first.value
            SBCF::SangerBarcode.new(prefix: 'BD', number: num_barcode).machine_barcode
          end

          step 'Perform bed verification' do
            # need subset of plates for the current pick number
            current_source_plates = current_expected_plates[pick_number_index][:sources]
            control_plate = current_expected_plates[pick_number_index][:control]

            step 'scan beds' do
              # fill in robot bed barcodes for sources
              # NB. screen erb seems to override key in robot properties and adds the space e.g. SCRC 1 not SCRC1
              (1..current_source_plates.count).each do |i|
                fill_in("SCRC #{i}", with: get_machine_barcode_for_bed("SCRC#{i}"))
              end

              # fill in robot bed barcode for control if present
              if control_plate
                if robot.robot_properties.exists?(key: 'CTRL1')
                  # This is for Hamilton robots, which have a control specific bed
                  fill_in('CTRL 1', with: get_machine_barcode_for_bed('CTRL1'))
                else
                  # This is for Tecan robots, where control plates are in a normal source bed
                  fill_in('CTRL 1', with: SBCF::SangerBarcode.new(prefix: 'BD', number: max_plates).machine_barcode)
                end
              end

              # fill in robot bed barcode for destination
              fill_in('DEST 1', with: get_machine_barcode_for_bed('DEST1'))
            end

            step 'scan plate barcodes' do
              # source plate barcodes
              current_source_plates.each { |plate| fill_in(plate.human_barcode, with: plate.human_barcode) }

              # control plate barcode
              fill_in(control_plate.human_barcode, with: control_plate.human_barcode) if control_plate

              # destination plate barcodes
              fill_in(destination_barcode, with: destination_barcode)
            end

            step 'optionally set custom destination plate type' do
              # optionally fill in custom plate type for the destination
              if custom_destination_type
                select(custom_destination_type_name, from: "plate_types[#{destination_barcode}]")
              end
            end

            step 'verify bed layout' do
              click_on('Verify')
            end
          end

          step "Download pick file for destination plate #{destination_barcode} pick number #{pick_number_index}" do
            Capybara.using_wait_time(5) do
              # This requires more time to perform the check between runs.
              # Throws a JS error if not waiting enough
              expect(page).to have_content("Download #{robot.name.capitalize} File Step 3 of 3")
            end

            click_link("Download #{robot.name} File")

            current_destination_plate = Plate.find_by_barcode(destination_barcode)

            # robot file generation differs by generator
            case robot.generation_behaviour_property.value
            when 'Hamilton'
              # for Robot::Generator::Hamilton
              # Hamilton files comprise a column headers row plus one row per transfer e.g.
              # rubocop:disable Layout/LineLength
              # SourcePlateID,SourceWellID,SourcePlateType,SourcePlateVolume,DestinationPlateID,DestinationWellID,DestinationPlateType,DestinationPlateVolume,WaterVolume
              # DN1000001A,A1,ABgene 0765,15.85,DN20000001B,A1,ABgene 0800,15.85,49.15
              # rubocop:enable Layout/LineLength
              generated_file =
                DownloadHelpers.downloaded_file(
                  "#{batch_id}_batch_#{destination_barcode}_#{pick_number_index}.csv",
                  timeout: 10
                )
              generated_lines = generated_file.lines

              expect(generated_lines).not_to be_empty

              # check generated lines match expected by calculation
              plates_and_controls_barcodes = [
                current_expected_plates[pick_number_index][:sources],
                current_expected_plates[pick_number_index][:control]
              ].flatten.compact.map(&:human_barcode)

              input_wells_requests_for_current_pick =
                current_destination_plate
                  .wells
                  .map(&:transfer_requests_as_target)
                  .select do |r|
                    # Assuming there is only one asset for the TransferRequest,
                    # As pooling is not supported in cherrypicking,
                    # ie. a well can only have one input sample
                    plates_and_controls_barcodes.include?(Labware.find(r.first.asset.labware_id).human_barcode)
                  end
              expected_num_lines = input_wells_requests_for_current_pick.count + NUM_HAMILTON_HEADER_LINES
              expect(generated_lines.length).to eq(expected_num_lines)

              # check count of controls present in destination file lines is correct,
              # but only in the first run, as controls should only be present in pick 1
              if control_plate
                count_control_plate_entries = 0
                generated_lines.each do |line|
                  count_control_plate_entries += 1 if /#{control_plate.human_barcode}/.match?(line)
                end

                if pick_number_index == 1
                  expect(count_control_plate_entries).to eq(control_plate.contained_samples.count)
                elsif pick_number_index > 1
                  expect(count_control_plate_entries).to eq(0)
                end
              end

              # optionally if an expected file was supplied, compare it to the result
              if expected_pick_files_by_destination_plate.present?
                # fetch our expected file structure
                expected_file = expected_pick_files_by_destination_plate[destination_barcode][pick_number_index]
                expected_file_lines = expected_file.lines

                expected_file_lines.each_with_index do |expected_line, index|
                  expect(generated_lines[index]).to eq(expected_line), "Error on line #{index} in #{expected_file}"
                end
              end
            when 'Tecan', 'TecanV2'
              # for Robot::Generator::Tecan
              # Tecan files start with 2 lines of dynamic information for user and date, e.g.
              # C;
              # C; This file created by user_abc6 on 2018-06-14 11:17:04 +0100

              # then a gap e.g.
              # C;

              # then 3 rows for each buffer transfer into the destination, e.g.
              # A;BUFF Trough;;Trough 100ml;1;;49.1
              # D;DN3U;;Custom Type;1;;49.1
              # W;

              # then a gap e.g.
              # C;

              # then 3 rows for each source to destination transfer, e.g.
              # A;DN1S;;ABgene 0765;1;;15.9
              # D;DN3U;;Custom Type;1;;15.9
              # W;

              # then a gap e.g.
              # C;

              # then rows for defining each bed, 1 per plate plus a gap e.g.
              # C; SCRC1 = DN1S
              # C; SCRC2 = DN2T
              # C;
              # C; DEST1 = DN3U
              generated_file =
                DownloadHelpers.downloaded_file(
                  "#{batch_id}_batch_#{destination_barcode}_#{pick_number_index}.gwl",
                  timeout: 10
                )
              generated_lines = generated_file.lines

              # check count of controls present in destination file lines is correct
              # NB. Tecan file has additional plate barcode lines at bottom of file for beds so add 1
              if control_plate
                count_control_plate_entries = 0
                generated_lines.each do |line|
                  count_control_plate_entries += 1 if /#{control_plate.human_barcode}/.match?(line)
                end
                expect(count_control_plate_entries).to eq(
                  control_plate.contained_samples.count + NUM_TECAN_EXTRA_BARCODE_LINES
                )
              end

              # optionally if an expected file was supplied. compare it to the result
              if expected_pick_files_by_destination_plate.present?
                # Shift off the dynamic comment lines
                generated_lines.shift(NUM_TECAN_HEADER_LINES)

                # fetch our expected file structure
                expected_file = expected_pick_files_by_destination_plate[destination_barcode][pick_number_index]
                expected_file_lines = expected_file.lines

                # Shift off the comment lines
                expected_file_lines.shift(NUM_TECAN_HEADER_LINES)

                expected_file_lines.each_with_index do |expected_line, index|
                  # Shift the error line number
                  error = <<~ERROR
                    Error on line #{index + NUM_TECAN_HEADER_LINES}
                    Expected Line: #{expected_line}
                    Actual Line: #{generated_lines[index]}
                    ---
                    Expected Output
                    #{expected_file}
                    ---
                    Actual Output
                    #{generated_file}
                  ERROR
                  expect(generated_lines[index]).to eq(expected_line), error
                end
              end
            end
          end
        end
      end
    end
  end
end
