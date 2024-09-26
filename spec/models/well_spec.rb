# frozen_string_literal: true

require 'timecop'

describe Well do
  subject(:well) { create(:well, well_attribute_attributes: well_attributes) }

  let(:well_attributes) { {} }

  describe '#update_gender_markers!' do
    context 'with gender_markers results' do
      let(:well_attributes) { { gender_markers: %w[M F F] } }

      it 'create an event if nothings changed and there are no previous events' do
        expect { well.update_gender_markers!(%w[M F F], 'SNP') }.to change { well.events.count }.by 1
      end

      it 'an event for each resource if nothings changed' do
        expect { well.update_gender_markers!(%w[M F F], 'MSPEC') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'MSPEC'
        expect { well.update_gender_markers!(%w[M F F], 'SNP') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'SNP'
      end

      it 'only 1 event if nothings changed for the same resource' do
        expect { well.update_gender_markers!(%w[M F F], 'SNP') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'SNP'

        # rubocop:todo Lint/AmbiguousBlockAssociation
        expect { well.update_gender_markers!(%w[M F F], 'SNP') }.not_to change { well.events.count }

        # rubocop:enable Lint/AmbiguousBlockAssociation
        expect(well.events.reload.last.content).to eq 'SNP'
      end
    end

    context 'without gender_markers results' do
      it 'an event for each resource if nothings changed' do
        expect { well.update_gender_markers!(%w[M F F], 'MSPEC') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'MSPEC'
        expect { well.update_gender_markers!(%w[M F F], 'SNP') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'SNP'
      end
    end
  end

  describe '#update_sequenom_count!' do
    context 'with sequenom_count results' do
      let(:well_attributes) { { sequenom_count: 5 } }

      it 'does not add an event if the value is the same' do
        expect { well.update_sequenom_count!(10, 'MSPEC') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'MSPEC'

        # rubocop:todo Lint/AmbiguousBlockAssociation
        expect { well.update_sequenom_count!(10, 'SNP') }.not_to change { well.events.count }

        # rubocop:enable Lint/AmbiguousBlockAssociation
        expect(well.events.reload.last.content).to eq 'MSPEC'
      end
    end

    context 'without sequenom_count results' do
      it 'add an event if its changed' do
        expect { well.update_sequenom_count!(10, 'MSPEC') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'MSPEC'
        expect { well.update_sequenom_count!(11, 'SNP') }.to change { well.events.count }.by 1
        expect(well.events.reload.last.content).to eq 'SNP'
      end
    end
  end

  describe '#update_from_qc' do
    let(:well_attributes) { { concentration: nil } }

    let(:qc_result) { build(:qc_result, key:, value:, units:, assay_type: 'assay', assay_version: 1) }

    before { well.update_from_qc(qc_result) }

    context 'key: concentration with nM' do
      let(:key) { 'concentration' }
      let(:value) { 100 }

      context 'units: nM' do
        let(:units) { 'nM' }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(well.get_concentration).to be_nil
          expect(well.get_molarity).to eq(100)
        end
      end

      context 'units: ng/ul' do
        let(:units) { 'ng/ul' }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(well.get_concentration).to eq(100)
          expect(well.get_molarity).to be_nil
        end
      end
    end

    context 'key: volume' do
      let(:key) { 'volume' }
      let(:units) { 'ul' }
      let(:value) { 100 }

      it { expect(well.get_volume).to eq(100) }
    end

    context 'key: volume, units: ml' do
      let(:key) { 'volume' }
      let(:units) { 'ml' }
      let(:value) { 1 }

      it { expect(well.get_volume).to eq(1000) }
    end

    context 'key: snp_count' do
      let(:key) { 'snp_count' }
      let(:units) { 'bases' }
      let(:value) { 100 }

      it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
        expect(well.get_sequenom_count).to eq(100)
        expect(well.events.reload.last.content).to eq 'assay 1'
      end
    end

    context 'key: loci_passed' do
      let(:key) { 'snp_count' }
      let(:units) { 'bases' }
      let(:value) { 100 }

      it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
        expect(well.get_sequenom_count).to eq(100)
        expect(well.events.reload.last.content).to eq 'assay 1'
      end
    end

    context 'key: gender_markers' do
      let(:key) { 'gender_markers' }
      let(:units) { 'bases' }
      let(:value) { 'MFU' }

      it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
        expect(well.get_gender_markers).to eq(%w[M F Unknown])
        expect(well.events.reload.last.content).to eq 'assay 1'
      end
    end

    context 'key: RIN' do
      let(:key) { 'RIN' }
      let(:units) { 'RIN' }
      let(:value) { 6 }

      it { expect(well.get_rin).to eq(6) }
    end
  end

  it 'return a correct hash of target wells' do
    purposes = create_list(:plate_purpose, 4)
    stock_plate = create(:plate_with_untagged_wells, sample_count: 3)

    norm_plates = purposes.map { |purpose| create(:plate_with_untagged_wells, purpose:, sample_count: 3) }

    well_plate_concentrations = [
      # Plate 1, Plate 2, Plate 3
      [50, 40, 60], # Well 1
      [30, nil, nil], # Well 2
      [10, nil, nil] # Well 3
    ]

    norm_plates.each_with_index do |plate, plate_index|
      plate.wells.each_with_index do |w, well_index|
        conc = well_plate_concentrations[well_index][plate_index]
        w.well_attribute.update(concentration: conc)
        stock_plate.wells[well_index].target_wells << w
      end
    end

    result = described_class.hash_stock_with_targets(stock_plate.wells, purposes.map(&:name))

    expect(result.count).to eq(3)
    expect(result[stock_plate.wells[1].id].count).to eq(1)
    expect(result[stock_plate.wells[2].id].count).to eq(1)
    expect(result[stock_plate.wells[0].id].count).to eq(3)
  end

  it 'have pico pass' do
    well.well_attribute.pico_pass = 'Yes'
    expect(well.get_pico_pass).to eq('Yes')
  end

  it 'have gel pass' do
    well.well_attribute.gel_pass = 'Pass'
    expect(well.get_gel_pass).to eq('Pass')
    assert well.get_gel_pass.is_a?(String)
  end

  it 'have picked volume' do
    well.set_picked_volume(3.6)
    expect(well.get_picked_volume).to eq(3.6)
  end

  it 'allow concentration to be set' do
    well.set_concentration(1.0)
    concentration = well.get_concentration
    expect(concentration).to eq(1.0)
    assert concentration.is_a?(Float)
  end

  it 'allow volume to be set' do
    well.set_current_volume(2.5)
    vol = well.get_volume
    expect(vol).to eq(2.5)
    assert vol.is_a?(Float)
  end

  it 'allow current volume to be set' do
    well.set_current_volume(3.5)
    vol = well.get_current_volume
    expect(vol).to eq(3.5)
    assert vol.is_a?(Float)
  end

  it 'record the initial volume as initial_volume' do
    well.well_attribute.measured_volume = 3.5
    vol = well.well_attribute.initial_volume
    expect(vol).to eq(3.5)
    well.well_attribute.measured_volume = 2.5
    orig_vol = well.well_attribute.initial_volume
    expect(orig_vol).to eq(3.5)
  end

  it 'allow buffer volume to be set' do
    well.set_buffer_volume(4.5)
    vol = well.get_buffer_volume
    expect(vol).to eq(4.5)
    assert vol.is_a?(Float)
  end

  context 'with a plate' do
    before do
      @plate = create(:plate)
      well.plate = @plate
    end

    it 'have a parent plate' do
      parent = well.plate
      assert parent.is_a?(Plate)
      expect(@plate.id).to eq(parent.id)
    end

    context 'for a tecan' do
      it 'have a parent plate' do
        parent = well.plate
        assert parent.is_a?(Plate)
        expect(@plate.id).to eq(parent.id)
      end
    end
  end

  [
    [1000, 10, 50, 50, 0, nil],
    [1000, 10, 10, 10, 0, nil],
    [1000, 10, 20, 10, 0, 10],
    [100, 100, 50, 1, 9, nil],
    [1000, 1000, 50, 1, 9, nil],
    [5000, 1000, 50, 5, 5, nil],
    [10, 100, 50, 1, 9, nil],
    [1000, 250, 50, 4, 6, nil],
    [10_000, 250, 50, 40, 0, nil],
    [10_000, 250, 30, 30, 0, nil]
    # rubocop:todo Metrics/ParameterLists
  ].each do |target_ng, measured_concentration, measured_volume, stock_to_pick, buffer_added, current_volume|
    # rubocop:enable Metrics/ParameterLists
    context 'cherrypick by nano grams' do
      before do
        @source_well = create(:well)
        @target_well = create(:well)
        minimum_volume = 10
        maximum_volume = 50
        robot_minimum_picking_volume = 1.0
        @source_well.well_attribute.update!(concentration: measured_concentration, measured_volume:, current_volume:)
        @target_well.volume_to_cherrypick_by_nano_grams(
          minimum_volume,
          maximum_volume,
          target_ng,
          @source_well,
          robot_minimum_picking_volume
        )
      end

      # rubocop:disable Layout/LineLength
      it "output stock_to_pick #{stock_to_pick} for a target of #{target_ng} with vol #{measured_volume} and conc #{measured_concentration}" do
        expect(@target_well.well_attribute.picked_volume).to eq(stock_to_pick)
      end

      # rubocop:enable Layout/LineLength

      # rubocop:disable Layout/LineLength
      it "output buffer #{buffer_added} for a target of #{target_ng} with vol #{measured_volume} and conc #{measured_concentration}" do
        expect(@target_well.well_attribute.buffer_volume).to eq(buffer_added)
      end
      # rubocop:enable Layout/LineLength
    end
  end

  context 'when while cherrypicking by nanograms' do
    context 'and we want to get less volume than the minimum' do
      before do
        @source_well = create(:well)
        @target_well = create(:well)

        @measured_concentration = 100
        @measured_volume = 50
        @target_ng = 10
        @minimum_volume = 10
        @maximum_volume = 50
      end

      it 'get correct volume and buffer volume when there is not robot minimum picking volume' do
        stock_to_pick = 0.1
        buffer_added = 9.9
        robot_minimum_picking_volume = nil
        @source_well.well_attribute.update!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(
          @minimum_volume,
          @maximum_volume,
          @target_ng,
          @source_well,
          robot_minimum_picking_volume
        )
        expect(@target_well.get_picked_volume).to eq(stock_to_pick)
        expect(@target_well.well_attribute.buffer_volume).to eq(buffer_added)
      end

      it "get correct buffer volume when it's above robot minimum picking volume" do
        stock_to_pick = 1
        buffer_added = 9
        robot_minimum_picking_volume = 1.0
        @source_well.well_attribute.update!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(
          @minimum_volume,
          @maximum_volume,
          @target_ng,
          @source_well,
          robot_minimum_picking_volume
        )
        expect(@target_well.get_picked_volume).to eq(stock_to_pick)
        expect(@target_well.well_attribute.buffer_volume).to eq(buffer_added)
      end

      it 'get no buffer volume if the minimum picking volume exceeds the minimum volume' do
        stock_to_pick = 10.0
        buffer_added = 0.0
        robot_minimum_picking_volume = 10.0
        @source_well.well_attribute.update!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(
          @minimum_volume,
          @maximum_volume,
          @target_ng,
          @source_well,
          robot_minimum_picking_volume
        )
        expect(@target_well.get_picked_volume).to eq(stock_to_pick)
        expect(@target_well.well_attribute.buffer_volume).to eq(buffer_added)
      end

      it 'get robot minimum picking volume if the correct buffer volume is below this value' do
        stock_to_pick = 5.0
        buffer_added = 5.0
        robot_minimum_picking_volume = 5.0
        @source_well.well_attribute.update!(concentration: @measured_concentration, measured_volume: @measured_volume)
        @target_well.volume_to_cherrypick_by_nano_grams(
          @minimum_volume,
          @maximum_volume,
          @target_ng,
          @source_well,
          robot_minimum_picking_volume
        )
        expect(@target_well.get_picked_volume).to eq(stock_to_pick)
        expect(@target_well.well_attribute.buffer_volume).to eq(buffer_added)
      end
    end
  end

  context 'to be cherrypicked' do
    context 'with no source concentration' do
      it 'raise an error' do
        assert_raises Cherrypick::ConcentrationError do
          well.volume_to_cherrypick_by_nano_grams_per_micro_litre(1.1, 2.2, 0.0, 20)
          well.volume_to_cherrypick_by_nano_grams_per_micro_litre(1.2, 2.2, '', 20)
        end
      end
    end

    it 'return volume to pick' do
      expect(well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0, 20)).to eq(1.25)
      expect(well.volume_to_cherrypick_by_nano_grams_per_micro_litre(13.0, 30.0, 100.0, 20)).to eq(3.9)
      expect(well.get_buffer_volume).to eq(9.1)
    end

    it 'sets the buffer volume' do
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0, 20)
      expect(well.get_buffer_volume).to eq(3.75)
      well.volume_to_cherrypick_by_nano_grams_per_micro_litre(13.0, 30.0, 100.0, 20)
      expect(well.get_buffer_volume).to eq(9.1)
    end

    it 'sets buffer and volume_to_pick correctly' do
      vol_to_pick = well.volume_to_cherrypick_by_nano_grams_per_micro_litre(5.0, 50.0, 200.0, 20)
      expect(vol_to_pick).to eq(well.get_picked_volume)
      expect(well.get_buffer_volume + vol_to_pick).to eq(5.0)
    end

    [
      [100.0, 50.0, 100.0, 200.0, nil, 50.0, 50.0, 'Standard scenario, sufficient material, buffer and dna both added'],
      [
        100.0,
        50.0,
        100.0,
        20.0,
        nil,
        20.0,
        80.0,
        'Insufficient source material for concentration or volume. Make up with buffer'
      ],
      [100.0, 5.0, 100.0, 2.0, nil, 2.0, 98.0, 'As above, just more extreme'],
      [100.0, 5.0, 100.0, 5.0, 5.0, 5.0, 95.0, 'High concentration, minimum robot volume increases source pick'],
      [100.0, 50.0, 52.0, 200.0, 5.0, 96.2, 5.0, 'Lowish concentration, non zero, but less than robot buffer required'],
      [100.0, 5.0, 100.0, 2.0, 5.0, 5.0, 98.0, 'Less DNA than robot minimum pick'],
      [100.0, 50.0, 1.0, 200.0, 5.0, 100.0, 0.0, 'Low concentration, maximum DNA, no buffer'],
      [120.0, 50.0, 0, 60.0, 5.0, 60.0, 60.0, 'Zero concentration, with less volume than required'],
      [120.0, 50.0, 0, 3.0, 5.0, 5.0, 117.0, 'Zero concentration, with less volume than even the minimum robot pick']
      # rubocop:todo Metrics/ParameterLists,Layout/LineLength
    ].each do |final_volume_desired, final_conc_desired, source_concentration, source_volume, robot_minimum_pick_volume, source_volume_obtained, buffer_volume_obtained, scenario|
      # rubocop:enable Metrics/ParameterLists,Layout/LineLength
      context "when testing #{scenario}" do
        before do
          @result_volume =
            format(
              '%.1f',
              well.volume_to_cherrypick_by_nano_grams_per_micro_litre(
                final_volume_desired,
                final_conc_desired,
                source_concentration,
                source_volume,
                robot_minimum_pick_volume
              )
            ).to_f
          @result_buffer_volume = format('%.1f', well.get_buffer_volume).to_f
        end

        it 'gets correct volume quantity' do
          expect(@result_volume).to eq(source_volume_obtained)
        end

        it 'gets correct buffer volume measures' do
          expect(@result_buffer_volume).to eq(buffer_volume_obtained)
        end
      end
    end
  end

  context 'proceed test' do
    before do
      @our_product_criteria = create(:product_criteria)
      @other_criteria = create(:product_criteria)

      @old_report =
        create(:qc_report,
               product_criteria: @our_product_criteria,
               created_at: 1.day.ago,
               report_identifier: "A#{Time.zone.now}")
      @current_report =
        create(:qc_report,
               product_criteria: @our_product_criteria,
               created_at: 1.hour.ago,
               report_identifier: "B#{Time.zone.now}")
      @unrelated_report =
        create(:qc_report,
               product_criteria: @other_criteria,
               created_at: Time.zone.now,
               report_identifier: "C#{Time.zone.now}")

      @stock_well = create(:well)

      well.stock_wells.attach!([@stock_well])
      well.reload

      create(:qc_metric, asset: @stock_well, qc_report: @old_report, qc_decision: 'passed', proceed: true)
      create(:qc_metric, asset: @stock_well, qc_report: @unrelated_report, qc_decision: 'passed', proceed: true)

      @expected_metric =
        create(:qc_metric, asset: @stock_well, qc_report: @current_report, qc_decision: 'failed', proceed: true)
    end

    it 'report appropriate metrics' do
      expect(well.latest_stock_metrics(@our_product_criteria.product)).to eq([@expected_metric])
    end
  end

  describe '#register_stock!' do
    subject { well.register_stock! }

    it 'allow registration of messengers' do
      expect { subject }.to change(Messenger, :count).by(1)
      expect(subject.root).to eq 'stock_resource'
      expect(subject.template).to eq 'WellStockResourceIO'
      expect(subject.target).to eq well
    end
  end

  it '#with qc results will show the qc results by key' do
    qc_results = [
      build(:qc_result_concentration),
      build(:qc_result_volume),
      build(:qc_result_molarity),
      build(:qc_result_rin)
    ]
    well = create(:well, qc_results:)
    expect(well.qc_results_by_key.size).to eq(4)
    expect(well.qc_results_by_key['concentration'].length).to eq(1)
  end

  describe '#qc_result_for' do
    it 'concentration' do
      qc_result_1 = build(:qc_result_concentration, value: '1.34523', created_at: Date.yesterday)
      qc_result_2 = build(:qc_result_concentration, value: '2.34523', created_at: Time.zone.today)
      well = create(:well, qc_results: [qc_result_1, qc_result_2])
      expect(well.qc_result_for('concentration')).to eq(2.345)
    end

    it 'volume' do
      qc_result_1 = build(:qc_result_volume, value: '1.34523', created_at: Date.yesterday)
      qc_result_2 = build(:qc_result_volume, value: '2.34523', created_at: Time.zone.today)
      well = create(:well, qc_results: [qc_result_1, qc_result_2])
      expect(well.qc_result_for('volume')).to eq(2.345)
    end

    it 'quantity_in_nano_grams' do
      well = create(:well)
      well.update_from_qc(build(:qc_result_volume, value: '1.34523'))
      expect(well.qc_result_for('quantity_in_nano_grams')).to be_present
    end

    it 'loci_passed (snp_count)' do
      qc_result_1 = build(:qc_result_loci_passed, value: '100', created_at: Date.yesterday)
      qc_result_2 = build(:qc_result_loci_passed, value: '110', created_at: Time.zone.today)
      well = create(:well, qc_results: [qc_result_1, qc_result_2])
      expect(well.qc_result_for('loci_passed')).to eq(110)
    end

    it 'RIN' do
      qc_result_1 = build(:qc_result_rin, value: '5', created_at: Date.yesterday)
      qc_result_2 = build(:qc_result_rin, value: '6', created_at: Time.zone.today)
      well = create(:well, qc_results: [qc_result_1, qc_result_2])
      expect(well.qc_result_for('rin')).to eq(6)
    end
  end

  context '(DPL-148) on updating well attribute' do
    let(:well) { create(:well) }

    it 'triggers warehouse update', :warren do
      expect do
        # We try a valid update
        well.well_attribute.update(concentration: 200)
      end.to change(Warren.handler.messages, :count).from(0)
    end
  end
end
