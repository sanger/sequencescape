# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception::Reconciliation do
  subject(:reconciliation) { described_class.new(payload_labware) }

  let(:plate) { create(:plate) }
  let(:tube) { create(:sample_tube) }

  def payload_labware_with(barcode, type: 'plate96', index: 0)
    ApiOperation::Reception::Payload::PayloadLabware.new(
      uuid: SecureRandom.uuid, barcode: barcode, type: type, receptacles: [],
      pointer: "/labware/#{index}"
    )
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
end
