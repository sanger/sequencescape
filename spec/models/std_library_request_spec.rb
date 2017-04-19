require 'rails_helper'

RSpec.describe IlluminaHtp::Requests::StdLibraryRequest, type: :model do
  subject { create :library_request, target_asset: tagged_well, state: state }
  let(:tagged_well) { create :tagged_well }

  context '#pass' do
    let(:state) { 'started' }

    before(:each) do
      expect(tagged_well.aliquots.first.library_id).to be_nil
      subject.pass!
    end

    it 'sets library parameters on aliquots in the target asset' do
      library = tagged_well
      aliquot = tagged_well.aliquots.first
      expect(aliquot.library_id).to eq(library.id)
      expect(aliquot.insert_size).to eq(subject.insert_size)
      expect(aliquot.library_type).to eq(subject.library_type)
    end
  end

  context '#request_metadata' do
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

    subject { (build :library_request, request_metadata_attributes: request_metadata_attributes) }

    it "has a fragment_size_required_from" do
      expect(subject.request_metadata.fragment_size_required_from).to eq(fragment_size_required_from)
    end
    context "without fragment_size_required_from" do
      let(:fragment_size_required_from) { nil }
      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    it "has a fragment_size_required_to" do
      expect(subject.request_metadata.fragment_size_required_to).to eq(fragment_size_required_to)
    end
    context "without fragment_size_required_to" do
      let(:fragment_size_required_to) { nil }
      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    it "has a library_type" do
      expect(subject.request_metadata.library_type).to eq(library_type)
    end
    context "without library_type" do
      let(:library_type) { nil }
      it 'is invalid' do
        # I thought library type WAS required. Oddly it doesn't appear to be.
        pending 'investigation into why this is failing'
        expect(subject).not_to be_valid
      end
    end

    it "has pcr_cycles" do
      expect(subject.request_metadata.pcr_cycles).to eq(pcr_cycles)
    end

    context "with a negative pcr_cycles" do
      let(:pcr_cycles) { -2 }
      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end

    context "with a non-number pcr_cycles" do
      let(:pcr_cycles) { 'two' }
      it 'is invalid' do
        expect(subject).not_to be_valid
      end
    end
  end
end
