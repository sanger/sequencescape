# frozen_string_literal: true

require 'rails_helper'

describe ReportFailsController, type: :controller do
  context 'with Report Fails' do
    let(:user) { create :user, barcode: 'ID48601I', swipecard_code: '02face' }
    let(:plate) { create :plate, barcode: 1 }
    let(:plate_2) { create :plate, barcode: 2 }
    let(:sample_tube) { create :sample_tube, barcode: 1 }

    shared_examples 'a successful failure event' do
      setup do
        post :create,
             params: {
               report_fail: {
                 barcodes: [plate.human_barcode, plate_2.machine_barcode, sample_tube.human_barcode],
                 user_code: SBCF::SangerBarcode.from_human(user.barcode).machine_barcode,
                 failure_id: failure_id
               }
             }
      end

      it 'Create failure events' do
        [plate, plate_2, sample_tube].each do |asset|
          expect(asset.events.last).to be_a Event::LabwareFailedEvent
          expect(BroadcastEvent::LabwareFailed.find_by(seed: asset)).to be_a BroadcastEvent::LabwareFailed
          expect(BroadcastEvent::LabwareFailed.find_by(seed: asset).to_json).to be_a String
        end
      end

      it('Sets the flash') { expect(flash.notice).to eq 'Failure saved' }
    end

    shared_examples 'an unsuccessful failure event' do
      setup do
        post :create,
             params: {
               report_fail: {
                 barcodes: [plate.human_barcode, plate_2.machine_barcode, sample_tube.human_barcode],
                 user_code: SBCF::SangerBarcode.from_human(user.barcode).machine_barcode,
                 failure_id: failure_id
               }
             }
      end

      it('Sets the flash') { expect(flash.notice).not_to eq 'Failure saved' }
    end

    describe '#create' do
      context 'with multiple assets' do
        let(:failure_id) { 'failure_id' }

        it_behaves_like 'a successful failure event'
      end

      context 'with no failure_id' do
        let(:failure_id) { '' }

        it_behaves_like 'an unsuccessful failure event'
      end
    end
  end
end
