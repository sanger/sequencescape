# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::Validation::ReceptacleValidation do
  subject(:validation) { described_class.new(identifier) }

  let(:plate) { create(:plate_with_untagged_wells, well_count: 1) }
  let(:tube) { create(:sample_tube) }

  context 'with an existing tube that has contents' do
    let(:identifier) { tube.human_barcode }

    it 'is valid' do
      expect(validation).to be_valid
    end

    it 'finds the tube receptacle' do
      expect(validation.receptacle).to eq(tube.receptacle)
    end
  end

  context 'with an existing well that has contents' do
    let(:identifier) { "#{plate.human_barcode}:A1" }

    it 'is valid' do
      expect(validation).to be_valid
    end
  end

  context 'with unknown labware' do
    let(:identifier) { 'NOPE' }

    it 'reports it at the requested labware identifiers' do
      expect(validation.errors.map(&:to_h)).to eq(
        [{ pointer: '/work_order/requested_labware_identifiers', detail: 'Cannot find labware with barcode "NOPE"' }]
      )
    end
  end

  context 'with a well that does not exist' do
    let(:identifier) { "#{plate.human_barcode}:H12" }

    it 'reports the well' do
      expect(validation.errors.pluck(:detail)).to eq(["Cannot find well \"H12\" on #{plate.human_barcode}"])
    end
  end

  context 'with an empty tube' do
    let(:tube) { create(:empty_sample_tube) }
    let(:identifier) { tube.human_barcode }

    it 'reports it is empty' do
      expect(validation.errors.pluck(:detail)).to eq(["#{identifier} is empty"])
    end
  end

  context 'with a plate barcode and no well' do
    let(:plate) { create(:plate_with_untagged_wells, well_count: 2) }
    let(:identifier) { plate.human_barcode }

    it 'is not valid' do
      expect(validation).not_to be_valid
    end
  end
end
