# frozen_string_literal: true

# Local to these SLF migrations: no Cucumber steps or suite-wide seed loading.
# Keep the original multi-page setup and scanner journeys together for comparison with the features.
# rubocop:disable-next Metrics/ModuleLength, Metrics/MethodLength, Metrics/AbcSize
module SlfCherrypickingHelpers
  attr_reader :source_plates, :destination

  # rubocop:disable-next Metrics/CyclomaticComplexity
  def released_cherrypicking_batch(sample_count: 2, barcodes: ['SQPD-1234567'], minimum_pick: '5.0', low: false)
    @user = create(:admin, login: 'user', barcode: 'ID41440E')
    login_user @user
    project = create(:project, name: 'Test project')
    study = create(:study, name: 'Test study', state: 'pending')
    study.activate!
    create(:stock_plate_purpose, name: 'Stock Plate')
    create(:plate_purpose, name: 'Infinium 670k', cherrypickable_target: true)
    create(:plate_type, name: 'ABgene_0765', maximum_volume: 800)
    create(:plate_type, name: 'ABgene_0800', maximum_volume: 180)
    pipeline = create(:cherrypick_pipeline, name: 'Cherrypick')
    group = study.asset_groups.create!(name: 'Plate asset group')
    @source_plates = barcodes.map do |barcode|
      plate = create(:plate, sanger_barcode: Barcode.build_sequencescape22(barcode:))
      sample_count.times do |index|
        well = create(:well, plate: plate, map: plate.maps.find_by!(row_order: index))
        well.aliquots.create!(sample: create(:sample, name: "Sample_#{barcode}_#{index + 1}"), study: study)
        group.assets << well
      end
      plate
    end

    # Preserve the source's real submission build and job, rather than mocking requests.
    template = create(:cherrypick_submission_template, request_types: pipeline.request_types.to_a)
    order = template.create_with_submission!(study: study, project: project, user: @user, assets: group.assets)
    order.submission.built!
    Delayed::Worker.new(quiet: true).work_off(1)
    expect(Delayed::Job.all.filter_map(&:last_error)).to be_empty
    expect(Delayed::Job.count).to eq(0)

    visit pipeline_path(pipeline)
    expect(page).to have_current_path(pipeline_path(pipeline))
    barcodes.each { |barcode| check "Select #{barcode} for batch" }
    first(:select, 'action_on_requests').select('Create Batch')
    first(:button, 'Submit').click

    # Same external HTTP boundary as Cucumber's @barcode-service hook.
    stub_request(:post, "#{configatron.baracoda_api}/barcodes/#{configatron.plate_barcode_prefix}/new")
      .to_return(status: 201, headers: { 'Content-Type' => 'text/json' }, body: { barcode: 'SQPD-99999' }.to_json)
    create(:plate_template)
    @robot = create(:robot, barcode: '444')
    { max_plates: '21', SCRC1: '1', SCRC2: '2', SCRC3: '3', DEST1: '20', generation_behaviour: 'Tecan' }
      .each { |key, value| @robot.robot_properties.create!(key: key.to_s, value: value) }
    @source_plates.each do |plate|
      # The plate factory cached an empty association before the wells were created separately.
      # Cucumber finds the plate afresh here, so reload before applying its QC results.
      expect(plate.wells.reload.size).to eq(sample_count)
      plate.wells.each_with_index do |well, index|
        well.well_attribute.update!(current_volume: 10 + (index % 30), concentration: (low ? 50 : 205) + (index % 50))
      end
    end

    click_link 'Select Plate Template'
    select 'test_plate_template', from: 'Plate Template'
    select 'Infinium 670k', from: 'Output plate purpose'
    select @robot.name, from: 'Picking Robot'
    select 'ABgene_0765', from: 'Source Plates Type'
    choose 'Pick by concentration (ng/µl)'
    fill_in 'nano_grams_per_micro_litre_volume_required', with: '13', fill_options: { clear: :backspace }
    fill_in 'nano_grams_per_micro_litre_concentration_required', with: '50'
    fill_in 'nano_grams_per_micro_litre_robot_minimum_picking_volume', with: minimum_pick
    click_button 'Next step'
    click_button 'Next step'
    click_button 'Release this batch'
    expect(page).to have_text('Batch released!')
    @batch = Batch.order(:id).last!
    @batch.update!(barcode: Barcode.number_to_human(550000555760))
    @destination = Plate.find_from_barcode('SQPD-99999')
    expect(@destination).to be_present
    @batch
  end

  def scan_verification(auto_submit: false)
    visit robot_verifications_path
    expect(page).to have_current_path(robot_verifications_path)
    {
      'Scan user ID' => '2470041440697',
      'Scan robot' => '4880000444853',
      'Scan worksheet' => '550000555760'
    }.each do |label, value|
      # Match the Gherkin docstrings: two trailing CRs for the user, one for other scans.
      suffix = "\n" * (label == 'Scan user ID' ? 2 : 1) if auto_submit
      find_field(label).send_keys("#{value}#{suffix}")
      # CR must not submit any of the first three scans.
      expect(page).to have_current_path(robot_verifications_path)
      expect(page).to have_field(label, with: value)
    end
    find_field('Scan destination plate').send_keys(auto_submit ? "SQPD-99999\n" : 'SQPD-99999')
    click_button 'Check' unless auto_submit
    expect(page).to have_text('Scan Robot Beds And Plates')
    expect_source_beds
  end

  def expect_source_beds
    expected = @source_plates.map(&:human_barcode).sort.each_with_index.map { |barcode, i| ["SCRC #{i + 1}", barcode] }
    expected << ['DEST 1', 'SQPD-99999']
    rows = find_by_id('source_beds').all('tbody tr')
    expect(rows.map { |row| row.all('td').values_at(0, 2).map(&:text) }).to eq(expected)
  end

  def verify_beds(carriage_returns: true)
    beds = {
      'SCRC 1' => '4880000001780',
      'SCRC 2' => '4880000002794',
      'SCRC 3' => '4880000003807',
      'DEST 1' => '4880000020729'
    }
    # Deliberately scan SQPD-5 before SQPD-10, as in the source feature.
    labels =
      if @source_plates.size == 3
        ['SCRC 1', 'SQPD-1', 'SCRC 2', 'SQPD-5', 'SCRC 3', 'SQPD-10', 'DEST 1', 'SQPD-99999']
      else
        ['SCRC 1', 'SQPD-1234567', 'DEST 1', 'SQPD-99999']
      end
    labels.each do |label|
      value = beds.fetch(label, label)
      if carriage_returns
        # A second CR would activate the focused Verify button and race the explicit click below.
        find_field(label).send_keys("#{value}\n")
      else
        fill_in label, with: value
      end
    end
    click_button 'Verify'
    expect(page).to have_text('Download myrobot File')
  end

  def expect_robot_download(buffer_volumes:, sample_volumes:, sources:)
    click_link 'Download myrobot File'
    file = DownloadHelpers.downloaded_file("#{@batch.id}_batch_SQPD-99999_1.gwl")
    expected = ['C;']
    buffer_volumes.each_with_index do |volume, index|
      expected.push(
        "A;BUFF;;96-TROUGH;#{index + 1};;#{volume}",
        "D;SQPD-99999;;ABgene 0800;#{index + 1};;#{volume}",
        'W;'
      )
    end
    expected << 'C;'
    sources.zip(sample_volumes).each_with_index do |((barcode, position), volume), index|
      expected.push(
        "A;#{barcode};;ABgene 0765;#{position};;#{volume}",
        "D;SQPD-99999;;ABgene 0800;#{index + 1};;#{volume}",
        'W;'
      )
    end
    expected << 'C;'
    @source_plates.map(&:human_barcode).sort.each_with_index do |barcode, index|
      expected << "C; SCRC#{index + 1} = #{barcode}"
    end
    expected.push('C;', 'C; DEST1 = SQPD-99999')
    # Only the timestamp/user header is excluded, exactly as in the source step.
    # Equality also detects missing or extra commands (the old step checked only a prefix).
    expect(file.lines(chomp: true).drop(2)).to eq(expected)
  end
end
