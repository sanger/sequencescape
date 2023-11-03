# frozen_string_literal: true

# Class that handles the access to Baracoda to obtain new barcodes
class PlateBarcode
  def self.site
    configatron.baracoda_api
  end

  def self.prefix
    configatron.plate_barcode_prefix
  end

  # Creates a new single barcode in baracoda
  # Returns:
  # - Barcode instance, using Sequencescape22 format
  def self.create_barcode
    response = fetch_response("#{site}/barcodes/#{prefix}/new")
    Barcode.build_sequencescape22(response)
  end

  # Creates a new single barcode with a code text in baracoda
  # Arguments:
  # text - str with the code of up to 3 characters that will be appended
  # after the prefix
  # Returns:
  # - Barcode instance, using Sequencescape22 format
  def self.create_barcode_with_text(text)
    response = fetch_response("#{site}/barcodes/#{prefix}/new", { text: text })
    Barcode.build_sequencescape22(response)
  end

  # Creates a new group of child barcodes from a parent barcode.
  # Args:
  # - parent_barcode - String with the barcode we want to create children from
  # - count - Number of children to create
  # Returns:
  # - Barcode instance, using Sequencescape22 format
  def self.create_child_barcodes(parent_barcode, count = 1)
    response = fetch_response("#{site}/child-barcodes/#{prefix}/new", { barcode: parent_barcode, count: count })
    response[:barcodes_group][:barcodes].map! { |barcode| Barcode.build_sequencescape22(barcode: barcode) }
  end

  # Obtain a record from Baracoda and retries the specified amount of time. If the number or retries is reached
  # the method will raise an exception
  # Args:
  # - http_connection - Net::HTTP instance to connect to the host/port
  # - request - Net::HTTP::Post object that contains the params for the request like the body, headers, etc
  # - retries - int, defaults to 3. Number of times it will retry to call baracoda. After that time period it
  #   will raise exception
  # - wait_timeout - float, defaults to 0.1 (100 ms). Time sleep in between calls to baracoda when connection
  #   is refused
  # Returns:
  # - Json parsed hash with the response from Baracoda
  # - If no answers is obtained, it raises an exception
  def self.fetch_response(url, data = nil, retries = 3, wait_timeout = 0.1)
    _connection_scope(url, data) do |http_connection, request|
      # Baracoda has a drop out bug, until this is fixed we need to retry a few times
      _retries_scope(retries, wait_timeout) do
        response = http_connection.request(request)
        return JSON.parse(response.body, symbolize_names: true) if response.code == '201'
      end
    end
    raise 'Could not obtain a barcode from Baracoda'
  end

  # Retries the number of times specified before calling the block. It
  # sleeps wait_timeout in between calls except with the last call.
  # Args:
  # - retries - int, Number of times it will retry to use the block
  # - wait_timeout - float. Time sleep in between calls to baracoda when connection
  #   is refused
  # Yields: Nothing
  def self._retries_scope(retries, wait_timeout)
    while retries.positive?
      begin
        yield
      rescue Errno::ECONNREFUSED
        Rails.logger.error('Failed connection to Baracoda')
      end
      sleep(wait_timeout) if retries >= 1
      retries -= 1
    end
  end

  # Creates required objects to perform a call to the server so they can be reused
  # inside the scope.
  # Args:
  # - url: string that contains the url to connect
  # - data: object that we will POST to the url. If not defined it will be an empty POST.
  # Yields:
  # - http_connection - Net::HTTP instance to connect to the host/port
  # - request - Net::HTTP::Post object that contains the params for the request like the body, headers, etc
  def self._connection_scope(url, data = nil)
    uri = URI(url)
    initheader = { 'Content-Type' => 'application/json' }
    request = Net::HTTP::Post.new(uri.path, initheader)
    request.body = data.to_json if data
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http_connection|
      yield http_connection, request
    end
  end

  if Rails.env.development?
    # If we don't want a test dependency on baracoda we need to mock barcodes and child barcodes

    #
    # When in development we were receiving concurrent requests for a barcode
    # we were experiencing a race condition where both requests were obtaining the same barcode.
    # To avoid it we will cache the barcodes and perform retry until unique barcode is
    # obtained
    extend Dev::PlateBarcode::CacheBarcodes

    def self.create_barcode
      # We should use a different prefix for local so that you can switch between using baracoda
      # locally and there will not be clashes

      # We cache the last barcode so we don't get race conditions on generating barcodes
      # when requests appear at the same time
      Barcode.build_sequencescape22({ barcode: "#{prefix}-#{dev_cache_get_next_barcode}" })
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
      barcode_record = fetch_response("#{site}/barcodes/#{prefix}/new")
      if barcode_record[:format] == 'DN'
        Barcode.build_sanger_code39(prefix: 'DN', number: barcode_record[:barcode])
      else
        Barcode.build_sequencescape22(barcode_record)
      end
    end
  end
end
