# frozen_string_literal: true

# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.

require 'rails_helper'

describe LabwhereReceptionsController do
  MockResponse = Struct.new(:valid?, :error)

  context 'Sample Reception' do
    let(:user) { create :user, barcode: 'ID123', swipecard_code: '02face' }
    let(:plate) { create :plate, barcode: 1 }
    let(:plate_2) { create :plate, barcode: 2 }
    let(:sample_tube) { create :sample_tube, barcode: 1 }

    shared_examples 'a reception' do
      setup do
        expect(LabWhereClient::Scan).to receive(:create).with(
          location_barcode: location_barcode, user_code: user.barcode, labware_barcodes: [plate.ean13_barcode, plate_2.ean13_barcode, sample_tube.ean13_barcode]
        ).and_return(MockResponse.new(true, ''))

        post :create, params: { labwhere_reception: {
          barcodes: [plate.ean13_barcode, plate_2.ean13_barcode, sample_tube.ean13_barcode],
          user_code: user.barcode,
          location_barcode: location_barcode
        } }
      end

      it 'Create reception events' do
        [plate, plate_2, sample_tube].each do |asset|
          expect(asset.events.last).to be_a Event::ScannedIntoLabEvent
          # expect(asset.events.last.message).to eq "Scanned into #{location.name}"
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
