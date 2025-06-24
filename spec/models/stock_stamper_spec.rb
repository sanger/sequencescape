# frozen_string_literal: true

require 'rails_helper'
require 'pry'
require 'timecop'

describe StockStamper do
  let(:plate) { create(:plate_with_3_wells) }
  let!(:user) { create(:user, login: 'abc', barcode: 'ID41440E') }

  before do
    # Set the plate barcode to be a DN barcode
    plate.barcodes = [Barcode.build_sanger_code39({ prefix: 'DN', number: '1' })]
    create(:plate_type, name: 'ABgene_0765', maximum_volume: 800)
    create(:plate_type, name: 'ABgene_0800', maximum_volume: 180)
    create(:plate_type, name: 'FluidX075', maximum_volume: 500)
    create(:plate_type, name: 'FluidX 0.5µl', maximum_volume: 520)
    create(:plate_type, name: 'FluidX03', maximum_volume: 280)

    @attributes = {
      user_barcode: '2470041440697',
      source_plate_barcode: plate.ean13_barcode,
      destination_plate_barcode: plate.ean13_barcode,
      source_plate_type_name: 'ABgene_0765',
      destination_plate_type_name: 'ABgene_0800',
      overage: 1.2
    }
    @stock_stamper = described_class.new(@attributes)
    new_time = Time.zone.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(new_time)
    @tecan_data = {
      'user' => user.login,
      'time' => new_time,
      'source' => {
        "#{plate.machine_barcode}_s" => {
          'name' => 'ABgene 0765',
          'plate_size' => 96
        }
      },
      'destination' => {
        "#{plate.machine_barcode}_d" => {
          'name' => 'ABgene 0800',
          'plate_size' => 96,
          'mapping' => [
            {
              'src_well' => ["#{plate.machine_barcode}_s", 'A1'],
              'dst_well' => 'A1',
              'volume' => 180.0,
              'buffer_volume' => 0.0
            },
            {
              'src_well' => ["#{plate.machine_barcode}_s", 'B2'],
              'dst_well' => 'B2',
              'volume' => 180.0,
              'buffer_volume' => 0.0
            },
            {
              'src_well' => ["#{plate.machine_barcode}_s", 'E6'],
              'dst_well' => 'E6',
              'volume' => 180.0,
              'buffer_volume' => 0.0
            }
          ]
        }
      }
    }
  end

  after { Timecop.return }

  describe 'it verifies the plates' do
    it 'is not valid without plates barcodes, user barcode, plates types' do
      invalid_stock_stamper = described_class.new
      expect(invalid_stock_stamper.valid?).to be false
      expect(invalid_stock_stamper.errors.messages.length).to eq 5
    end

    it 'is not valid if user barcode or plate barcode are invalid' do
      invalid_stock_stamper =
        described_class.new(
          @attributes.merge(source_plate_barcode: '123', destination_plate_barcode: '234', user_barcode: '345')
        )
      expect(invalid_stock_stamper.valid?).to be false
      expect(invalid_stock_stamper.errors.messages.length).to eq 3
      expect(invalid_stock_stamper.errors.full_messages).to include 'User is not registered in Sequencescape'
      expect(invalid_stock_stamper.errors.full_messages).to include 'Plate is not registered in Sequencescape'
      expect(invalid_stock_stamper.errors.full_messages).to include 'Plates barcodes are not identical'
    end

    it 'is valid if correct attributes provided' do
      expect(@stock_stamper.valid?).to be true
      expect(@stock_stamper.plate).to be_a Plate
      expect(@stock_stamper.user).to be_a User
    end
  end

  describe 'generate tecan file' do
    it 'generates the right tecan data' do
      expect(@stock_stamper.generate_tecan_data).to eq @tecan_data
    end

    it 'generates the right tecan file' do
      file = File.open('spec/data/tecan/stock_stamper.gwl', 'rb')
      expected_output = file.read
      @stock_stamper.generate_tecan_gwl_file_as_text
      expect(@stock_stamper.file_content).to eq expected_output
    end

    it 'creates asset_audit on plate' do
      @stock_stamper.create_asset_audit_event
      expect(@stock_stamper.plate.asset_audits.length).to eq 1
      expect(@stock_stamper.plate.asset_audits.first.message).to eq "Process 'Stamping of stock' performed"
    end

    it 'creates correct message after execution' do
      @stock_stamper.execute
      expect(@stock_stamper.message).to eq(
        notice: 'You can generate the TECAN file and print label now.',
        error:
          # rubocop:todo Layout/LineLength
          'Required volume exceeds the maximum well volume for well(s) A1, B2, E6. Maximum well volume 180.0 will be used in tecan file'
        # rubocop:enable Layout/LineLength
      )
    end
  end
end
