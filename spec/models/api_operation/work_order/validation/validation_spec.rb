# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::Validation::Validation do
  subject(:validation) { described_class.new(api_operation) }

  let(:plate) { create(:plate_with_untagged_wells, well_count: 1) }
  let(:identifiers) { ["#{plate.human_barcode}:A1", 'NOPE'] }
  let(:work_order) do
    { external_id: 'WO1', service_name: 'Human Exome', requested_by: 'user', cost_code: 'S1234',
      requested_labware_identifiers: identifiers, options: {} }
  end
  let(:api_operation) { create(:api_operation, payload: { work_order: }.to_json) }

  it 'reports only the problem identifiers, each at its own index' do
    expect(validation.errors.pluck(:pointer)).to eq(['/work_order/requested_labware_identifiers/1'])
  end

  context 'when all the labware is fine' do
    let(:identifiers) { ["#{plate.human_barcode}:A1"] }

    it 'finds no errors' do
      expect(validation.errors).to be_empty
    end
  end

  context 'without requested labware identifiers' do
    let(:identifiers) { nil }

    it 'reports the missing field' do
      expect(validation.errors.pluck(:pointer)).to eq(['/work_order/requested_labware_identifiers'])
    end
  end

  context 'with several required fields missing' do
    let(:work_order) { { service_name: ' ', requested_labware_identifiers: ['NOPE'], options: {} } }

    it 'reports each missing field and skips labware checks' do
      expect(validation.errors.pluck(:pointer)).to eq(
        %w[/work_order/external_id /work_order/service_name /work_order/requested_by /work_order/cost_code]
      )
    end
  end
end
