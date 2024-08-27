# frozen_string_literal: true

require 'rails_helper'

describe LabwhereReceptionsController do
  context 'Sample Reception' do
    let(:user) { create :user, barcode: 'ID48601I', swipecard_code: '02face' }
    let(:plate) { create :plate }
    let(:plate_2) { create :plate }
    let(:sample_tube) { create :sample_tube, barcode: 1 }

    shared_examples 'a reception' do
      before do
        expect(LabWhereClient::Scan).to receive(:create).with(
          location_barcode: location_barcode,
          user_code: SBCF::SangerBarcode.from_human(user.barcode).machine_barcode.to_s,
          labware_barcodes: [plate.human_barcode, plate_2.machine_barcode, sample_tube.human_barcode]
        ).and_return(instance_double(LabWhereClient::Scan, valid?: true, error: ''))

        post :create,
             params: {
               labwhere_reception: {
                 barcodes: [plate.human_barcode, plate_2.machine_barcode, sample_tube.human_barcode],
                 user_code: SBCF::SangerBarcode.from_human(user.barcode).machine_barcode,
                 location_barcode: location_barcode
               }
             }
      end

      it 'Create reception events' do
        [plate, plate_2, sample_tube].each do |asset|
          expect(asset.events.last).to be_a(Event::ScannedIntoLabEvent).or be_a(Event::RetentionInstructionEvent)
          expect(BroadcastEvent::LabwareReceived.find_by(seed: asset)).to be_a BroadcastEvent::LabwareReceived
          expect(BroadcastEvent::LabwareReceived.find_by(seed: asset).to_json).to be_a String
        end
      end

      it('Sets the flash') { expect(flash.notice).to eq 'Locations updated!' }
    end

    describe '#create' do
      context 'with multiple assets' do
        let(:location_barcode) { 'labwhere_location' }

        it_behaves_like 'a reception'
      end

      context 'with no location' do
        let(:location_barcode) { '' }

        it_behaves_like 'a reception'
      end
    end
  end
end
