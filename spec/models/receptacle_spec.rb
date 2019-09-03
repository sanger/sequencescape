# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Receptacle, type: :model do
  let(:receptacle) { create :receptacle }
  # Uhh, looks like all our asset tests were labware tests!

  it 'can be created' do
    expect(receptacle).to be_a described_class
  end

  describe '#update_from_qc' do
    let(:qc_result) { build :qc_result, key: key, value: value, units: units, assay_type: 'assay', assay_version: 1 }

    setup { receptacle.update_from_qc(qc_result) }
    context 'when key: molarity with nM' do
      let(:key) { 'molarity' }
      let(:value) { 100 }

      context 'when units: nM' do
        let(:units) { 'nM' }

        it 'works', :aggregate_failures do
          expect(tube.concentration).to eq(100)
        end
      end
    end

    context 'when key: volume' do
      let(:key) { 'volume' }
      let(:units) { 'ul' }
      let(:value) { 100 }

      it { expect(tube.volume).to eq(100) }
    end

    context 'when key: volume, units: ml' do
      let(:key) { 'volume' }
      let(:units) { 'ml' }
      let(:value) { 1 }

      it { expect(tube.volume).to eq(1000) }
    end
  end
end
