# frozen_string_literal: true

require 'timecop'

describe Tube do
  subject(:tube) { create :tube }

  describe '#update_from_qc' do
    let(:qc_result) { build :qc_result, key: key, value: value, units: units, assay_type: 'assay', assay_version: 1 }
    setup { tube.update_from_qc(qc_result) }
    context 'key: molarity with nM' do
      let(:key) { 'molarity' }
      let(:value) { 100 }

      context 'units: nM' do
        let(:units) { 'nM' }
        it 'works', :aggregate_failures do
          expect(tube.concentration).to eq(100)
        end
      end
    end

    context 'key: volume' do
      let(:key) { 'volume' }
      let(:units) { 'ul' }
      let(:value) { 100 }
      it { expect(tube.volume).to eq(100) }
    end
    context 'key: volume, units: ml' do
      let(:key) { 'volume' }
      let(:units) { 'ml' }
      let(:value) { 1 }
      it { expect(tube.volume).to eq(1000) }
    end
  end
end
