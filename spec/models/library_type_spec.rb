# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LibraryType do
  subject { described_class.new(name: name) }

  context 'without a name' do
    let(:name) { '' }

    it { is_expected.not_to be_valid }
  end

  context 'with a unique name' do
    let(:name) { 'Unique' }

    it { is_expected.to be_valid }
  end

  context 'with a shared name' do
    before { create :library_type, name: 'Shared' }

    let(:name) { 'Shared' }

    it { is_expected.not_to be_valid }
  end

  context 'with a shared name (case-insensitive)' do
    before { create :library_type, name: 'Shared' }

    let(:name) { 'shared' }

    it { is_expected.not_to be_valid }
  end

  describe '::alphabetical' do
    before do
      create :library_type, name: 'Brilliant'
      create :library_type, name: 'Amazing'
      create :library_type, name: 'Cool'
    end

    it 'returns library types in alphabetical order' do
      expect(described_class.alphabetical.pluck(:name)).to eq(%w[Amazing Brilliant Cool])
    end
  end

  describe '::long_read' do
    let(:record_loader) { RecordLoader::LibraryTypeLoader.new(files: ['001_long_read']) }
    let(:expected_library_types) do
      %w[
        Pacbio_HiFi
        Pacbio_HiFi_mplx
        Pacbio_IsoSeq
        PacBio_IsoSeq_mplx
        Pacbio_Microbial_mplx
        PacBio_Ultra_Low_Input
        PacBio_Ultra_Low_Input_mplx
      ]
    end

    before do
      create :library_type, name: 'Not long read'
      record_loader.create!
    end

    it 'returns long_read library types only' do
      expect(described_class.long_read.pluck(:name)).to eq(expected_library_types)
    end
  end
end
