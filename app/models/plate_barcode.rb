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

  def self.create_child_barcodes(parent_barcode, count=1)
    retries = 0
    uri = URI("#{site}/child-barcodes/new")
    http = Net::HTTP.new(uri.host, uri.port)
    req  = Net::HTTP::Post.new(uri.path, initheader = {'Content-Type' =>'application/json'})
    req.body = { barcode: parent_barcode, count: count }.to_json
    # Baracoda has a drop out bug, until this is fixed we need to retry a few times
    while retries < 3 do
      begin
        response = http.request(req)
        if response.code === "201"
          response = JSON.parse(response.body, symbolize_names: true)
          retries = 3
        end
        retries += 1
      rescue Errno::ECONNREFUSED
        retries += 1
      end
    end
    response[:barcodes].map! { |barcode| Barcode.build_sequencescape22(barcode) }
  end

  if Rails.env.development?
    # If we don't want a test dependency on baracoda we need to mock barcodes and child barcodes

    def self.create_barcode
      # We should use a different prefix for local so that you can switch between using baracoda locally and there will not be clashes
      current_num = Barcode.sequencescape22.order(id: :desc).first&.number || 9000
      Barcode.build_sequencescape22({ barcode: "#{self.prefix}-#{current_num + 1}" })
    end

    def self.create_child_barcodes(parent_barcode, count=1)
      child_barcodes = []

      current_child = Barcode.find_by_barcode(parent_barcode).child_barcodes.order(id: :desc).first
      
      # gets the 'child count' section of the barcode SQPD-12345-(1) as an int
      # if its the first child then current_child is blank and we set the count to 0
      current_child_count = current_child.blank? ? 0 : current_child.barcode.split("-").last.to_i

      # creates new child barcodes based on existing ones
      (1..count).each do |num|
        child_barcodes << Barcode.build_sequencescape22({barcode: "#{parent_barcode}-#{current_child_count + num}"})
      end

      child_barcodes
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
