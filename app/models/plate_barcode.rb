# frozen_string_literal: true

# Class that handles the access to Baracoda to obtain new barcodes
class PlateBarcode
  self.site = configatron.baracoda_api
  self.prefix = configatron.plate_barcode_prefix

  def self.site=(site)
    self.site = site
  end

  # Creates a new single barcode in baracoda
  # Returns:
  # - Barcode instance, using Sequencescape22 format
  def self.create_barcode
    uri = URI("#{site}/barcodes/#{prefix}/new")
    http_connection = Net::HTTP.new(uri.host, uri.port)
    Barcode.build_sequencescape22(fetch_barcode(http_connection))
  end

  # Creates a new group of child barcodes from a parent barcode.
  # Args:
  # - parent_barcode - String with the barcode we want to create children from
  # - count - Number of children to create
  # Returns:
  # - Barcode instance, using Sequencescape22 format
  def self.create_child_barcodes(parent_barcode, count = 1)
    uri = URI("#{site}/child-barcodes/new")
    http_connection = Net::HTTP.new(uri.host, uri.port)
    initheader = { 'Content-Type' => 'application/json' }
    request = Net::HTTP::Post.new(uri.path, initheader)
    request.body = { barcode: parent_barcode, count: count }.to_json
    response = fetch_response(http_connection, request)
    response[:barcodes].map! { |barcode| Barcode.build_sequencescape22(barcode) }
  end

  # Obtain a record from Baracoda and retries the specified amount of time. If the number or retries is reached
  # the method will raise an exception
  # Args:
  # - http_connection - Net::HTTP instance to connect to the host/port
  # - request - Net::HTTP::Post object that contains the params for the request like the body, headers, etc
  # - retries - int, defaults to 3. Number of times it will retry to call baracoda. After that time period it
  #   will raise exception
  # - wait_timeout - floate, defaults to 0.1 (100 ms). Time sleep in between calls to baracoda when connection
  #   is refused
  # Returns:
  # - Json parsed hash with the response from Baracoda
  # - If no answers is obtained, it raises an exception
  def self.fetch_response(http_connection, request = nil, retries = 3, wait_timeout = 0.1)
    # Baracoda has a drop out bug, until this is fixed we need to retry a few times
    while retries.positive?
      begin
        response = http_connection.request(request)
        return JSON.parse(response.body, symbolize_names: true) if response.code == '201'
      rescue Errno::ECONNREFUSED
        Rails.logger.error('Failed connection to Baracoda')
      end
      sleep(wait_timeout) if retries >= 1
      retries -= 1
    end
    raise 'Could not obtain a barcode from Baracoda'
  end

  if Rails.env.development?
    # If we don't want a test dependency on baracoda we need to mock barcodes and child barcodes

    def self.create_barcode
      # We should use a different prefix for local so that you can switch between using baracoda
      # locally and there will not be clashes
      current_num = Barcode.sequencescape22.order(id: :desc).first&.number || 9000
      Barcode.build_sequencescape22({ barcode: "#{prefix}-#{current_num + 1}" })
    end

    def self.create_child_barcodes(parent_barcode, count = 1)
      child_barcodes = []

      current_child = Barcode.find_by_barcode(parent_barcode).child_barcodes.order(id: :desc).first

      # gets the 'child count' section of the barcode SQPD-12345-(1) as an int
      # if its the first child then current_child is blank and we set the count to 0
      current_child_count = current_child.blank? ? 0 : current_child.barcode.split('-').last.to_i

      # creates new child barcodes based on existing ones
      (1..count).each do |num|
        child_barcodes << Barcode.build_sequencescape22({ barcode: "#{parent_barcode}-#{current_child_count + num}" })
      end

      child_barcodes
    end
  end

  if Rails.env.cucumber?
    def self.create_barcode
      uri = URI("#{site}/barcodes/#{prefix}/new")
      http_connection = Net::HTTP.new(uri.host, uri.port)
      barcode_record = fetch_barcode(http_connection)
      if barcode_record[:format] == 'DN'
        Barcode.build_sanger_code39(prefix: 'DN', number: barcode_record[:barcode])
      else
        Barcode.build_sequencescape22(barcode_record)
      end
    end
  end
end
