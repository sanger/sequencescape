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
          barcode = JSON.parse(response.body, symbolize_names: true)
          retries = 3
        end
        retries += 1
      rescue Errno::ECONNREFUSED
        retries += 1
      end
    end

    Barcode.build_sequencescape22(barcode)
  end

  if Rails.env.development?
    # If we don't want a test dependency on baracoda we need to mock a barcode

    def self.create_barcode
      # We should use a different prefix for local so that you can switch between using baracoda locally and there will not be clashes
      current_num = Barcode.sequencescape22.order(id: :desc).first&.number || 9000
      Barcode.build_sequencescape22({ barcode: "#{self.prefix}-#{current_num + 1}" })
    end
  end

  if Rails.env.cucumber?
    def self.create_barcode()
      uri = URI("#{site}/barcodes/#{prefix}/new")
      response = Net::HTTP.post(uri, "")
      if response.code === "201"
        barcode_record = JSON.parse(response.body, symbolize_names: true)
      end
      if barcode_record[:format] == 'DN'
        Barcode.build_sanger_code39(prefix: 'DN', number: barcode_record[:barcode])
      else
        Barcode.build_sequencescape22(barcode_record)
      end
    end
  end
end
