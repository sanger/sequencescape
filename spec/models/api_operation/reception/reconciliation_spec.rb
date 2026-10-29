# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Reconciliation do
  subject(:reconciliation) { described_class.new(payload_labware) }

  let(:plate) { create(:plate) }
  let(:tube) { create(:sample_tube) }

  def payload_labware_with(barcode, type: 'plate96', index: 0, contents: {})
    pointer = "/labware/#{index}"
    receptacles =
      contents.each_with_index.map do |(position, names), receptacle_index|
        payload_receptacle(position, names,
                           "#{pointer}/receptacles/#{receptacle_index}")
      end
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: barcode, type: type,
      receptacles: receptacles, pointer: pointer
    )
  end

  def payload_receptacle(position, names, pointer)
    samples =
      names.each_with_index.map do |name, index|
        payload_sample(name, "#{pointer}/samples/#{index}")
      end
    ApiOperation::Reception::Payload::PayloadReceptacle.new(
      position: position, uuid: SecureRandom.uuid, samples: samples,
      pointer: pointer
    )
  end

  def payload_sample(name, pointer)
    ApiOperation::Reception::Payload::PayloadSample.new(
      uuid: SecureRandom.uuid, study_uuid: SecureRandom.uuid,
      sanger_sample_id: "SAMPLE-#{name}", supplier_sample_name: name,
      fields: {}, pointer: pointer
    )
  end

  # The supplier sample names in each well of the plate that holds samples
  def contents_of(plate)
    plate.wells.reject { it.aliquots.empty? }.to_h do |well|
      [well.map_description,
       well.samples.map { it.sample_metadata.supplier_name }]
    end
  end

  # The SQL queries the block runs, other than transaction bookkeeping
  def queries_in(&)
    queries = []
    count = ->(*, payload) { queries << payload[:sql] }
    ActiveSupport::Notifications.subscribed(count, 'sql.active_record', &)
    queries.grep_v(/\A\s*(SAVEPOINT|RELEASE|ROLLBACK|BEGIN|COMMIT)/)
  end

  context 'with a plate Sequencescape has' do
    let(:payload_labware) { [payload_labware_with(plate.human_barcode)] }

    it 'matches it to the plate' do
      expect(reconciliation.matched).to eq(payload_labware.first => plate)
    end

    it 'has no new labware' do
      expect(reconciliation.new_labware).to be_empty
    end
  end

  context 'with a tube Sequencescape has' do
    let(:payload_labware) do
      [payload_labware_with(tube.human_barcode, type: 'tube')]
    end

    it 'matches it to the tube' do
      expect(reconciliation.matched).to eq(payload_labware.first => tube)
    end
  end

  context "with another of the labware's barcodes" do
    let(:payload_labware) { [payload_labware_with('EXTERNAL-1')] }

    before { plate.barcodes.create!(barcode: 'EXTERNAL-1', format: :external) }

    it 'matches it to the labware' do
      expect(reconciliation.matched).to eq(payload_labware.first => plate)
    end
  end

  context 'with a barcode Sequencescape does not know' do
    let(:payload_labware) { [payload_labware_with('UNKNOWN-1')] }

    it 'matches nothing' do
      expect(reconciliation.matched).to be_empty
    end

    it 'is new labware' do
      expect(reconciliation.new_labware).to eq(payload_labware)
    end
  end

  context 'with known and unknown labware' do
    let(:payload_labware) do
      [payload_labware_with('UNKNOWN-1', index: 0),
       payload_labware_with(plate.human_barcode, index: 1),
       payload_labware_with('UNKNOWN-2', index: 2)]
    end

    it 'matches the known labware' do
      expect(reconciliation.matched.keys).to eq([payload_labware[1]])
    end

    it 'keeps the new labware in payload order' do
      expect(reconciliation.new_labware)
        .to eq([payload_labware[0], payload_labware[2]])
    end
  end

  context 'with several plates' do
    let(:plates) { create_list(:plate, 3) }
    # Built first, so creating the plates isn't counted
    let!(:payload_labware) do
      plates.each_with_index.map do |each_plate, index|
        payload_labware_with(each_plate.human_barcode, index:)
      end
    end
    let(:one_plate) { described_class.new([payload_labware.first]) }

    it 'looks them up with as many queries as for one' do
      expect(queries_in { reconciliation.matched }.size)
        .to eq(queries_in { one_plate.matched }.size)
    end
  end

  describe '#errors' do
    let(:plate) { create(:plate_with_untagged_wells, sample_count: 2) }
    let(:barcode) { plate.human_barcode }
    let(:contents) { contents_of(plate) }
    let(:payload_labware) do
      [payload_labware_with(barcode, contents:)]
    end

    before do
      plate.wells.each do |well|
        well.samples.each do |sample|
          sample.sample_metadata
            .update!(supplier_name: "Supplier #{well.map_description}")
        end
      end
    end

    it 'finds none when the plate is the same' do
      expect(reconciliation.errors).to be_empty
    end

    it 'finds none for new labware' do
      new_labware = [payload_labware_with('UNKNOWN-1')]
      expect(described_class.new(new_labware).errors).to be_empty
    end

    context 'when the payload says tube' do
      let(:payload_labware) do
        [payload_labware_with(barcode, type: 'tube', contents: contents)]
      end

      it 'reports the type' do
        expect(reconciliation.errors).to eq(
          [{ pointer: '/labware/0/type',
             detail: "#{barcode} is a 96-well plate in Sequencescape, " \
                     'not a tube' }]
        )
      end
    end

    context 'when the payload says a 384-well plate' do
      let(:payload_labware) do
        [payload_labware_with(barcode, type: 'plate384', contents: contents)]
      end

      it 'reports the size' do
        expect(reconciliation.errors.sole[:detail])
          .to eq("#{barcode} is a 96-well plate in Sequencescape, " \
                 'not a 384-well plate')
      end
    end

    context 'when a well has another sample in the payload' do
      let(:contents) do
        contents_of(plate).merge('A1' => ['Supplier A1', 'Another'])
      end

      it 'reports the well and the number of samples' do
        expect(reconciliation.errors).to eq(
          [{ pointer: '/labware/0/receptacles/0',
             detail: "well A1 of #{barcode} has 1 sample in Sequencescape, " \
                     'not 2 samples' }]
        )
      end
    end

    context 'when a well has another supplier sample name' do
      let(:contents) { contents_of(plate).merge('A1' => ['Another']) }

      it 'reports the well' do
        expect(reconciliation.errors.sole[:detail])
          .to eq("well A1 of #{barcode} has different supplier sample " \
                 'names in Sequencescape')
      end
    end

    context 'when the payload leaves out a well with samples' do
      let(:contents) { contents_of(plate).except('B1') }

      it 'reports the well against the plate' do
        expect(reconciliation.errors).to eq(
          [{ pointer: '/labware/0',
             detail: "well B1 of #{barcode} has 1 sample in Sequencescape, " \
                     'not 0 samples' }]
        )
      end
    end

    context 'when the payload lists an empty well' do
      let(:contents) { contents_of(plate).merge('H12' => []) }

      it 'finds none' do
        expect(reconciliation.errors).to be_empty
      end
    end

    context 'when the payload lists samples in an empty well' do
      let(:contents) { contents_of(plate).merge('H12' => ['Another']) }

      it 'reports the well' do
        expect(reconciliation.errors.sole[:detail])
          .to eq("well H12 of #{barcode} has 0 samples in Sequencescape, " \
                 'not 1 sample')
      end
    end

    context 'with a tube' do
      let(:tube) { create(:sample_tube) }
      let(:barcode) { tube.human_barcode }

      before do
        tube.samples.sole.sample_metadata.update!(supplier_name: 'Tube sample')
      end

      it 'finds none when the tube is the same' do
        payload_labware =
          [payload_labware_with(barcode, type: 'tube',
                                         contents: { nil => ['Tube sample'] })]
        expect(described_class.new(payload_labware).errors).to be_empty
      end

      it 'reports different supplier sample names' do
        payload_labware =
          [payload_labware_with(barcode, type: 'tube',
                                         contents: { nil => ['Another'] })]
        expect(described_class.new(payload_labware).errors.sole[:detail])
          .to eq("the tube of #{barcode} has different supplier sample " \
                 'names in Sequencescape')
      end
    end

    context 'with several plates' do
      let(:plates) { create_list(:plate_with_untagged_wells, 3) }
      # Built first, so creating the plates isn't counted
      let!(:payload_labware) do
        plates.each_with_index.map do |each_plate, index|
          payload_labware_with(each_plate.human_barcode, index:)
        end
      end
      let(:one_plate) { described_class.new([payload_labware.first]) }

      it 'compares them with as many queries as for one' do
        expect(queries_in { reconciliation.errors }.size)
          .to eq(queries_in { one_plate.errors }.size)
      end
    end
  end
end
