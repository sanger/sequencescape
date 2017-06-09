require 'rails_helper'

RSpec.describe TransferRequest, type: :model do
  let!(:source) { LibraryTube.create!.tap { |tube| tube.aliquots.create!(sample: create(:sample)) } }
  let!(:tag) { create(:tag).tag!(source) }
  let!(:destination) { LibraryTube.create! }

  context 'TransferRequest' do
    context 'when using the constuctor' do
      let!(:transfer_request) { RequestType.transfer.create!(asset: source, target_asset: destination) }

      it 'should duplicate the aliquots' do
        expected_aliquots = source.aliquots.map { |a| [a.sample_id, a.tag_id] }
        target_aliquots   = destination.aliquots.map { |a| [a.sample_id, a.tag_id] }
        expect(target_aliquots).to eq expected_aliquots
      end

      it 'should have the correct attributes' do
        expect(transfer_request.request_type).to eq RequestType.find_by(key: 'transfer')
        expect(transfer_request.sti_type).to eq 'TransferRequest'
        expect(transfer_request.state).to eq 'pending'
        expect(transfer_request.asset_id).to eq source.id
        expect(transfer_request.target_asset_id).to eq destination.id
      end
    end

    it 'should assign correct attributes if attributes were not passed' do
      transfer_request = TransferRequest.create(asset: source, target_asset: destination)
      transfer_request_type = RequestType.find_by(key: 'transfer')
      expect(transfer_request.request_type).to eq transfer_request_type
      expect(transfer_request.request_purpose).to eq transfer_request_type.request_purpose
    end

    it 'should assign correct attributes if attributes were passed' do
      request_type = RequestType.find_by(key: 'initial_transfer')
      request_purpose = RequestPurpose.find_by(key: 'control')
      transfer_request = TransferRequest.create(asset: source, target_asset: destination, request_type: request_type, request_purpose: request_purpose)
      expect(transfer_request.request_type).to eq request_type
      expect(transfer_request.request_purpose).to eq request_purpose
    end

    it 'should not permit transfers to the same asset' do
      asset = create(:sample_tube)
      expect { RequestType.transfer.create!(asset: asset, target_asset: asset) }.to raise_error(ActiveRecord::RecordInvalid)
    end

    context 'with a tag clash' do
      let!(:tag) { create :tag }
      let!(:tag2) { create :tag }
      let!(:aliquot_1) { create :aliquot, tag: tag, tag2: tag2, receptacle: create(:well) }
      let!(:aliquot_2) { create :aliquot, tag: tag, tag2: tag2, receptacle: create(:well) }
      let!(:target_asset) { create :well }

      it 'should raise an exception' do
        transfer_request = RequestType.transfer.create!(asset: aliquot_1.receptacle.reload, target_asset: target_asset)
        expect { RequestType.transfer.create!(asset: aliquot_2.receptacle.reload, target_asset: target_asset) }.to raise_error(Aliquot::TagClash)
      end
    end
  end
end
