# frozen_string_literal: true
class PlateBarcode < ActiveResource::Base # rubocop:todo Style/Documentation
  self.site = configatron.baracoda_api
  self.prefix = configatron.plate_barcode_prefix

  def self.create_barcode()
    retries = 0
    barcode = nil
    uri = URI("#{site}/barcodes/#{prefix}/new")

    # Baracoda has a drop out bug, until this is fixed we need to retry a few times
    while retries < 3 do
      begin
        response = Net::HTTP.post(uri, "")
        if response.code === "201"
          barcode = JSON.parse(response.body)["barcode"]
          retries = 3
        end
        retries += 1
      rescue Errno::ECONNREFUSED
        retries += 1
      end
    end

    barcode
  end

  if Rails.env.development?
    MockBarcode = Struct.new(:barcode)

    def self.create
      @barcode ||= Barcode.sanger_code39.where('barcode LIKE "DN%"').order(barcode: :desc).first&.number || 9_000_000
      MockBarcode.new(@barcode += 1)
    end
  end
end
