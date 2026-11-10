# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility do
  subject(:feasibility) { described_class.new(requested_receptacles, options) }

  let(:donors) { %w[D1 D2 D3 D4 D5 D6 D7 D8 D9 D10] }
  let(:identifiers) { donors.each_index.map { |i| "PLATE-X:A#{i + 1}" } }
  let(:options) { { 'number_of_pools' => 2, 'cells_per_chip_well' => 20_000 } }
  let(:requested_receptacles) { ApiOperation::WorkOrder::RequestedReceptacles.new(identifiers) }

  before do
    receptacles = identifiers.zip(donors).to_h do |identifier, donor|
      sample = create(:sample, sample_metadata: create(:sample_metadata, donor_id: donor))
      [identifier, create(:well, aliquots: [create(:aliquot, sample:)])]
    end
    allow(ApiOperation::WorkOrder::Validation::ReceptacleValidation).to receive(:new) do |identifier, **|
      instance_double(ApiOperation::WorkOrder::Validation::ReceptacleValidation,
                      identifier: identifier, receptacle: receptacles[identifier])
    end
  end

  context 'with a feasible work order' do
    it { expect(feasibility.errors).to be_empty }
  end

  context 'without the pooling options' do
    let(:options) { {} }

    it 'points at each missing option' do
      expect(feasibility.errors.map(&:pointer)).to eq(
        %w[/work_order/options/number_of_pools /work_order/options/cells_per_chip_well]
      )
    end
  end

  context 'with zero for an option' do
    let(:options) { { 'number_of_pools' => 0, 'cells_per_chip_well' => 20_000 } }

    it 'only reports the option, without checking the pooling' do
      expect(feasibility.errors.map(&:pointer)).to eq(['/work_order/options/number_of_pools'])
    end
  end

  context 'with too few samples' do
    let(:donors) { %w[D1 D2 D3] }
    let(:options) { { 'number_of_pools' => 1, 'cells_per_chip_well' => 20_000 } }

    it 'points at the requested labware' do
      expect(feasibility.errors.map(&:pointer)).to include('/work_order/requested_labware_identifiers')
    end
  end

  context 'with too many pools' do
    let(:options) { { 'number_of_pools' => 9, 'cells_per_chip_well' => 20_000 } }

    it 'points at the number of pools' do
      expect(feasibility.errors.map(&:pointer)).to include('/work_order/options/number_of_pools')
    end
  end

  context 'with more samples of a donor than pools' do
    let(:donors) { %w[D1 D1 D1 D2 D3 D4 D5 D6 D7 D8] }

    it 'lists the identifiers of the clashing samples' do
      expect(feasibility.errors.map(&:detail).join).to include('PLATE-X:A1, PLATE-X:A2, PLATE-X:A3')
    end
  end
end
