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
          barcode = JSON.parse(response.body)
          retries = 3
        end
        retries += 1
      rescue Errno::ECONNREFUSED
        retries += 1
      end
    end

    barcode
  end

  if Rails.env.development? || Rails.env.cucumber?
    # If we don't want a test dependency on baracoda we need to mock a barcode

    def self.create_barcode
      current_num = Barcode.sequencescape22.order(barcode: :desc).first&.number || 1
      { barcode: "#{self.prefix}-#{current_num + 1}" }
    end
  end
end
