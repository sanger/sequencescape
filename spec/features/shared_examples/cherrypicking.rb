# frozen_string_literal: true

shared_examples 'a cherrypicking procedure' do
  attr_reader :batch_id
  attr_reader :batch_barcode

  it 'can process the cherrypicking' do
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

    step 'Printing the worksheets' do
      step 'Extract the batch identifier' do
        within('.page-header') do
          @batch_id = page.find('.subtitle').text
          @batch_barcode = Barcode.calculate_barcode('BA', batch_id)
        end
      end

      step 'Print and check the worksheet for each output destination plate' do
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
    end

    step 'Perform the bed verifications' do
      step 'Bed verifiy each output destination plate pick' do
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
end
