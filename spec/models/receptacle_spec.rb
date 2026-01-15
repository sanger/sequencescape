# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Receptacle do
  let(:receptacle) { create(:receptacle) }

  # Uhh, looks like all our asset tests were labware tests!

  it 'can be created' do
    expect(receptacle).to be_a described_class
  end

  describe '#most_recent_requests_as_target_group_by_same_source' do
    let(:source) { create(:receptacle) }
    let(:source2) { create(:receptacle) }
    let(:requests_source1) { create_list(:request, 3, { asset: source }) }
    let(:requests_source2) { create_list(:request, 2, { asset: source2 }) }
    let(:requests) { [requests_source1, requests_source2].flatten }
    let(:expected) { [requests_source1.last, requests_source2.last].flatten }

    before { receptacle.requests_as_target << requests }

    it 'returns the most recent active request as target' do
      expect(receptacle.most_recent_requests_as_target_group_by_same_source).to eq(expected)
    end
  end

  describe '#update_from_qc' do
    let(:qc_result) { build(:qc_result, key: key, value: value, units: units, assay_type: 'assay', assay_version: 1) }

    before { receptacle.update_from_qc(qc_result) }

    context 'when key: molarity with nM' do
      let(:key) { 'molarity' }
      let(:value) { 100 }

      context 'when units: nM' do
        let(:units) { 'nM' }

        it 'works', :aggregate_failures do # rubocop:todo RSpec/ExampleWording
          expect(receptacle.concentration).to eq(100)
        end
      end
    end

    context 'when key: volume' do
      let(:key) { 'volume' }
      let(:units) { 'ul' }
      let(:value) { 100 }

      it { expect(receptacle.volume).to eq(100) }
    end

    context 'when key: volume, units: ml' do
      let(:key) { 'volume' }
      let(:units) { 'ml' }
      let(:value) { 1 }

      it { expect(receptacle.volume).to eq(1000) }
    end
  end

  describe '#pcr_cycles' do
    let(:receptacle) { create(:receptacle, pcr_cycles: 10) }

    it { expect(receptacle.pcr_cycles).to eq 10 }
  end

  describe '#submit_for_sequencing' do
    let(:receptacle) { create(:receptacle, submit_for_sequencing: true) }

    it { expect(receptacle.submit_for_sequencing).to be true }
  end

  describe '#sub_pool' do
    let(:receptacle) { create(:receptacle, sub_pool: 5) }

    it { expect(receptacle.sub_pool).to eq 5 }
  end

  describe '#coverage' do
    let(:receptacle) { create(:receptacle, coverage: 100) }

    it { expect(receptacle.coverage).to eq 100 }
  end

  describe '#diluent_volume' do
    let(:receptacle) { create(:receptacle, diluent_volume: 40) }

    it { expect(receptacle.diluent_volume).to eq 40 }
  end

  describe '#attach_tag' do
    let(:tag1) { create(:tag) }
    let(:tag2) { create(:tag) }
    let(:receptacle) { create(:receptacle) }

    before { receptacle.update(aliquots:) }

    context 'when the receptacle has no aliquots' do
      let(:aliquots) { [] }

      it 'raises an error' do
        expect { receptacle.attach_tag(tag1, tag2) }.to raise_error(StandardError)
      end
    end

    context 'when the receptacle has one aliquot' do
      let(:aliquots) { [al1] }
      let(:al1) { create(:aliquot) }

      it 'can attach a tag to an aliquot' do
        receptacle.attach_tag(tag1, tag2)
      end
    end

    context 'when the receptacle has many aliquots' do
      let(:aliquots) { [al1, al2] }

      context 'when every aliquot has a different tag_depth' do
        let(:al1) { create(:aliquot, tag_depth: 1) }
        let(:al2) { create(:aliquot, tag_depth: 2) }

        it 'can attach a tag to every aliquot' do
          receptacle.attach_tag(tag1, tag2)
        end
      end

      context 'when there is duplication in tag_depths' do
        let(:al1) { create(:aliquot, tag_depth: 1) }
        let(:al2) { create(:aliquot, tag_depth: 1) }

        it 'raises an error' do
          expect { receptacle.attach_tag(tag1, tag2) }.to raise_error(StandardError)
        end
      end

      context 'when there is no tag_depth' do
        let(:al1) { create(:aliquot) }
        let(:al2) { create(:aliquot) }

        it 'raises an error' do
          expect { receptacle.attach_tag(tag1, tag2) }.to raise_error(StandardError)
        end
      end
    end
  end

  describe '#public_name' do
    let(:receptacle) { create(:receptacle, labware:) }

    context 'when a receptacle has a labware' do
      let(:labware) { create(:labware, public_name: 'Labware Name') }

      it { expect(receptacle.public_name).to eq 'Labware Name' }
    end
  end

  context 'when a receptacle does not have a labware' do
    # This happens with old receptacles that are missing a plate and are requested on deprecated endpoints
    let(:labware) { nil }

    it 'returns nil' do
      expect(receptacle.public_name).to be_nil
    end
  end
end
