require 'rails_helper'
require 'pry'
require 'timecop'

describe StockStamper do

  let!(:plate) { create :plate_with_3_wells, barcode: 1 }
  let!(:plate2) { create :plate_with_3_wells, barcode: 2 }
  let!(:user) { create :user, login: 'abc', barcode: "ID41440E" }

  before(:each) do
    @attributes = {user: "2470041440697",
              source_plate: plate.ean13_barcode,
              destination_plate: plate.ean13_barcode,
              source_plate_type: 'ABgene_0765',
              destination_plate_type: 'ABgene_0800',
              destination_plate_maximum_volume: '100',
              overage: 1.2}
    @stock_stamper = StockStamper.new(@attributes)
    new_time = Time.local(2008, 9, 1, 12, 0, 0)
    Timecop.freeze(new_time)
    @tecan_data = {
                    "user" => user.login,
                    "time" => new_time,
                    "source" =>
                    {
                      "#{plate.ean13_barcode}_s" =>
                      {
                        "name" => "ABgene 0765",
                        "plate_size" => 96
                      }
                    },
                    "destination" =>
                    {
                      "#{plate.ean13_barcode}_d"=>
                      {
                        "name" => "ABgene 0800",
                        "plate_size" => 96,
                        "mapping" => [
                          {
                            "src_well" => [
                              "#{plate.ean13_barcode}_s",
                              "A1"
                            ],
                            "dst_well" => "A1",
                            "volume" => 18.0,
                            "buffer_volume" => 0.0
                          },
                          {
                            "src_well" => [
                              "#{plate.ean13_barcode}_s",
                              "B2"
                            ],
                            "dst_well" => "B2",
                            "volume" => 18.0,
                            "buffer_volume" => 0.0
                          },
                          {
                            "src_well" => [
                              "#{plate.ean13_barcode}_s",
                              "E6"
                            ],
                            "dst_well" => "E6",
                            "volume" => 18.0,
                            "buffer_volume" => 0.0
                          }
                        ]
                      }
                    }
                  }
  end

  describe 'it verifies the plates' do

    it 'should not be valid without plates, user, plates types, destination plate maximum volume and overage' do
      invalid_stock_stamper = StockStamper.new
      expect(invalid_stock_stamper.valid?).to be false
      expect(invalid_stock_stamper.errors.messages.length).to eq 7
      expect(invalid_stock_stamper.errors.full_messages).to include "User barcode invalid"
      expect(invalid_stock_stamper.errors.full_messages).to include "Source plate barcode invalid"
      expect(invalid_stock_stamper.errors.full_messages).to include "Destination plate barcode invalid"
    end

    it 'should not be valid if user barcode or plate barcodes are invalid' do
      invalid_stock_stamper = StockStamper.new(@attributes.merge(source_plate: '123', destination_plate: '234', user: '345'))
      expect(invalid_stock_stamper.valid?).to be false
      expect(invalid_stock_stamper.errors.messages.length).to eq 3
      expect(invalid_stock_stamper.errors.full_messages).to include "User barcode invalid"
      expect(invalid_stock_stamper.errors.full_messages).to include "Source plate barcode invalid"
      expect(invalid_stock_stamper.errors.full_messages).to include "Destination plate barcode invalid"
    end

    it 'should not be valid if plates barcodes are not identical' do
      invalid_stock_stamper = StockStamper.new(@attributes.merge(destination_plate: plate2.ean13_barcode))
      expect(invalid_stock_stamper.valid?).to be false
      expect(invalid_stock_stamper.errors.messages.length).to eq 1
      expect(invalid_stock_stamper.errors.full_messages).to include "Plates barcodes are not identical"
    end

    it 'should be valid if correct attributes provided' do
      expect(@stock_stamper.valid?).to be true
      expect(@stock_stamper.source_plate).to be_a Plate
      expect(@stock_stamper.destination_plate).to be_a Plate
    end

  end

  describe 'generate tecan file' do

    it 'should generate the right tecan data' do
      expect(@stock_stamper.generate_tecan_data).to eq @tecan_data
    end

    it 'should generate the right tecan file' do
      file = File.open(configatron.tecan_files_location + "/tecan/" + "stock_stamper.gwl", "rb")
      expected_output = file.read
      expect(@stock_stamper.generate_tecan_gwl_file_as_text).to eq expected_output
    end

    it 'should create asset_audit on plate' do
      @stock_stamper.create_asset_audit_event
      expect(@stock_stamper.destination_plate.asset_audits.length).to eq 1
      expect(@stock_stamper.destination_plate.asset_audits.first.message).to eq "Process 'Stamping of stock' performed"
    end

  end

  after do
    Timecop.return
  end

end