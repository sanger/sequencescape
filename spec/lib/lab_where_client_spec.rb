# frozen_string_literal: true
require 'spec_helper'
require 'lab_where_client'

RSpec.describe LabWhereClient do
  describe LabWhereClient::Scan do
    let(:scan_params) { { 'message' => 'Scan successful', 'errors' => nil } }
    let(:scan) { described_class.new(scan_params) }

    it 'has the correct attributes' do
      expect(scan.message).to eq('Scan successful')
      expect(scan.errors).to be_nil
    end

    it 'has the correct endpoint_name' do
      expect(described_class.endpoint).to eq('scans')
    end

    it 'has a response_message' do
      expect(scan.response_message).to eq('Scan successful')
    end

    it 'has the correct creation_params' do
      expect(described_class.creation_params(labware_barcodes: %w[123 456])).to eq(
        scan: {
          labware_barcodes: "123\n456"
        }
      )
    end

    describe '#create' do
      it 'posts a scan to LabWhere' do
        labwhere = instance_double(LabWhereClient::LabWhere)
        allow(LabWhereClient::LabWhere).to receive(:new).and_return(labwhere)
        allow(labwhere).to receive(:post)
        described_class.create(location_barcode: '123', user_code: '456', labware_barcodes: ['789'])
        expect(labwhere).to have_received(:post).with(
          described_class,
          nil,
          { scan: { labware_barcodes: '789', user_code: '456', location_barcode: '123' } }
        )
      end

      it 'raises an error when Labwhere is down' do
        labwhere = instance_double(LabWhereClient::LabWhere)
        allow(LabWhereClient::LabWhere).to receive(:new).and_return(labwhere)
        allow(labwhere).to receive(:post).and_raise(LabWhereClient::LabwhereException.new, 'LabWhere service is down')

        expect do
          described_class.create(location_barcode: '123', user_code: '456', labware_barcodes: ['789'])
        end.to raise_error(LabWhereClient::LabwhereException, 'LabWhere service is down')
      end
    end

    describe '#valid?' do
      it 'returns true when there are no errors' do
        expect(scan.valid?).to be true
      end

      it 'returns false when there are errors' do
        scan_params['errors'] = 'Error message'
        expect(scan.valid?).to be false
      end
    end
  end
end
