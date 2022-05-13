# frozen_string_literal: true
RSpec.describe PlateBarcode do
  let(:plate_barcode) { described_class }

  describe '#create_barcode' do
    before { allow(plate_barcode).to receive(:fetch_response).and_return(barcode_record) }

    let(:barcode_record) { { barcode: 'SQPD-12345' } }

    it 'creates a new barcode' do
      obtained = plate_barcode.create_barcode
      expect(obtained.barcode).to eq(barcode_record[:barcode])
    end
  end

  describe '#create_child_barcodes' do
    before do allow(plate_barcode).to receive(:fetch_response).and_return(
        barcodes_group: { barcodes: barcode_records }
      )
    end

    let(:barcode_records) { ['SQPD-12345-1', 'SQPD-12345-2' ] }

    it 'creates a new barcode' do
      obtained = plate_barcode.create_child_barcodes('SQPD-12345', 2)
      expect(obtained.map(&:barcode)).to eq(barcode_records.pluck(:barcode))
    end
  end

  describe '#fetch_response' do
    let(:valid_content) { {} }
    let(:response_received) { instance_double(Net::HTTPResponse, body: valid_content.to_json, code: '201') }
    let(:http_connection) do
      instance_double(Net::HTTP).tap do |conn|
        repeats = 0
        allow(conn).to receive(:request) do
          if repeats == max_failures
            response_received
          else
            repeats += 1
            raise Errno::ECONNREFUSED
          end
        end
      end
    end
    let(:request) { instance_double(Net::HTTP::Post) }
    let(:url) { configatron.baracoda_api }

    before { allow(described_class).to receive(:_connection_scope).and_yield(http_connection, request) }

    context 'when it does not fail' do
      let(:max_failures) { 0 }

      it 'succeeds receiving the message' do
        expect(http_connection).to receive(:request).once
        expect(plate_barcode.fetch_response(url)).to eq(valid_content)
      end
    end

    context 'when it fails less than the defined maximum' do
      let(:defined_maximum) { 3 }
      let(:max_failures) { 2 }

      it 'succeeds receiving the message' do
        expect(http_connection).to receive(:request).exactly(3).times
        expect(plate_barcode.fetch_response(url, nil, defined_maximum)).to eq(valid_content)
      end
    end

    context 'when it fails in the response' do
      let(:defined_maximum) { 3 }
      let(:max_failures) { 2 }
      let(:response_received) { instance_double(Net::HTTPResponse, body: valid_content.to_json, code: '500') }

      it 'raises an error' do
        expect(http_connection).to receive(:request).exactly(3).times
        expect { plate_barcode.fetch_response(url, nil, defined_maximum) }.to raise_error(StandardError)
      end
    end

    context 'when it fails the defined maximum allowed' do
      let(:defined_maximum) { 3 }
      let(:max_failures) { 3 }

      it 'raises an error' do
        expect(http_connection).to receive(:request).exactly(3).times
        expect { plate_barcode.fetch_response(url, nil, defined_maximum) }.to raise_error(StandardError)
      end
    end
  end
end
