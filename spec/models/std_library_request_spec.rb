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
end
