# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IlluminaHtp::Requests::StdLibraryRequest, type: :model do
  let(:tagged_well) { create :tagged_well }

  describe '#pass' do
    subject { create :library_request, target_asset: tagged_well, state: state }

    let(:state) { 'started' }

    it 'can pass' do
      expect(tagged_well.aliquots.first.library_id).to be_nil
      subject.pass!
    end
  end

  describe '#request_metadata' do
    subject { build :library_request, request_metadata_attributes: request_metadata_attributes, request_type: request_type }

    let(:fragment_size_required_from) { 1 }
    let(:fragment_size_required_to)   { 20 }
    let(:library_type) { create(:library_type).name }
    let(:pcr_cycles) { 8 }

    let(:request_metadata_attributes) do
      {
        fragment_size_required_from: fragment_size_required_from,
        fragment_size_required_to: fragment_size_required_to,
        library_type: library_type,
        pcr_cycles: pcr_cycles
      }
    end

    let(:request_type) { create :library_creation_request_type }

    let(:expected_pool_info) do
      {
        insert_size: { from: fragment_size_required_from, to: fragment_size_required_to },
        library_type: { name: library_type },
        request_type: subject.request_type.key,
        pcr_cycles: pcr_cycles,
        for_multiplexing: false
      }
    end

    it 'has a fragment_size_required_from' do
      expect(subject.request_metadata.fragment_size_required_from).to eq(fragment_size_required_from)
    end

    context 'without fragment_size_required_from' do
      let(:fragment_size_required_from) { nil }

      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    it 'has a fragment_size_required_to' do
      expect(subject.request_metadata.fragment_size_required_to).to eq(fragment_size_required_to)
    end

    context 'without fragment_size_required_to' do
      let(:fragment_size_required_to) { nil }

      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    it 'has a library_type' do
      expect(subject.request_metadata.library_type).to eq(library_type)
    end

    it 'has pcr_cycles' do
      expect(subject.request_metadata.pcr_cycles).to eq(pcr_cycles)
    end

    context 'with a negative pcr_cycles' do
      let(:pcr_cycles) { -2 }

      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    context 'with a non-number pcr_cycles' do
      let(:pcr_cycles) { 'two' }

      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    context 'with a configured pcr_cycle range of 0 only' do
      before do
        request_type.request_type_validators << create(:pcr_cycles_validator)
      end

      context 'with a valid cycle' do
        let(:pcr_cycles) { 0 }

        it('is valid') { expect(subject).to be_valid }
      end

      context 'with an invalid cycle' do
        let(:pcr_cycles) { 4 }

        it('is invalid') { expect(subject).not_to be_valid }
      end

      context 'with an nil cycle' do
        let(:pcr_cycles) { nil }

        it('is valid') { expect(subject).to be_valid }
        # Defaults are set on a before validate call.

        it('sets defaults') do
          subject.valid?
          expect(subject.request_metadata.pcr_cycles).to eq(0)
        end
      end
    end

    context 'with a configured pcr_cycle range' do
      before do
        request_type.request_type_validators << create(:pcr_cycles_validator, valid_options: (1..25))
      end

      context 'with a valid cycle' do
        let(:pcr_cycles) { 5 }

        it('is valid') { expect(subject).to be_valid }
      end

      context 'with an invalid cycle' do
        let(:pcr_cycles) { 90 }

        it('is invalid') { expect(subject).not_to be_valid }
      end

      context 'with an nil cycle' do
        let(:pcr_cycles) { nil }

        it('is invalid') { expect(subject).not_to be_valid }
      end
    end

    it '#update_pool_information' do
      hash = {}
      subject.update_pool_information(hash)
      expect(hash).to eq(expected_pool_info)
    end
  end
end
