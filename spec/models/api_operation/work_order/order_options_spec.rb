# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApiOperation::WorkOrder::OrderOptions do
  subject(:order_options) { described_class.new(template, options, requested_receptacles) }

  let(:options) { { 'read_length' => 150, 'number_of_pools' => 2 } }
  let(:requested_receptacles) { instance_double(ApiOperation::WorkOrder::RequestedReceptacles) }

  context 'with the scRNA Core cDNA Prep template' do
    let(:template) { build(:submission_template, name: Submission::ScrnaCoreCdnaPrepFeasibilityCalculator::SCRNA_CORE_CDNA_PREP_GEM_X_5P) }

    before do
      feasibility = instance_double(ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility,
                                    allowance_band: '2 pool attempts, 2 counts')
      allow(ApiOperation::WorkOrder::Validation::ScrnaCoreCdnaPrepFeasibility)
        .to receive(:new).with(requested_receptacles, options).and_return(feasibility)
    end

    it 'merges the allowance band into the options of the work order' do
      expect(order_options.all_options).to eq(options.merge('allowance_band' => '2 pool attempts, 2 counts'))
    end

    it 'leaves the work order options as they are' do
      order_options.all_options
      expect(options).not_to have_key('allowance_band')
    end
  end

  context 'with another template' do
    let(:template) { build(:submission_template, name: 'Limber-Htp - LCMB') }

    it { expect(order_options.all_options).to eq(options) }
  end
end
