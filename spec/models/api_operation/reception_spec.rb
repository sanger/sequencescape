# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::Reception do
  subject(:reception) { described_class.new(api_operation) }

  let(:api_operation) do
    create(:api_operation, payload: { labware: [labware] }.to_json)
  end

  def labware_with(barcode, type: 'plate96')
    { uuid: SecureRandom.uuid, barcode: barcode, type: type, receptacles: [] }
  end

  context 'with new labware' do
    let(:labware) { labware_with('UNKNOWN-1') }

    it 'finds no errors' do
      expect(reception.call).to be_empty
    end
  end

  context 'with known labware that is the same' do
    let(:plate) { create(:plate) }
    let(:labware) { labware_with(plate.human_barcode) }

    it 'finds no errors' do
      expect(reception.call).to be_empty
    end
  end

  context 'with known labware that differs' do
    let(:plate) { create(:plate) }
    let(:labware) { labware_with(plate.human_barcode, type: 'tube') }

    it 'reports the conflict' do
      expect(reception.call).to eq(
        [{ pointer: '/labware/0/type',
           detail: "#{plate.human_barcode} is a 96-well plate in " \
                   'Sequencescape, not a tube' }]
      )
    end
  end
end
