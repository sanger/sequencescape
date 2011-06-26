require File.expand_path(File.join(File.dirname(__FILE__), 'fake_sinatra_service.rb'))

class FakeBarcodeService < FakeSinatraService
  attr_reader :wsdl

  # Ensure that the configuration is maintained, otherwise things start behaving badly
  # when it comes to the features.
  def self.install_hooks(target, tags)
    target.instance_eval do
      plate_url, service_url = configatron.plate_barcode_service, configatron.barcode_service_ul
      Before(tags) do |scenario|
        host, port = FakeBarcodeService.instance.host, FakeBarcodeService.instance.port
        configatron.plate_barcode_service = "http://#{host}:#{port}/plate_barcode_service/"
        configatron.barcode_service_url   = "http://#{host}:#{port}/barcode_service.wsdl"
        PlateBarcode.site                 = configatron.plate_barcode_service
      end
      After(tags) do |scenaro|
        configatron.plate_barcode_service = plate_url
        configatron.barode_service_url    = service_url
        PlateBarcode.site                 = configatron.plate_barcode_service
      end
    end

    super
  end

  def initialize(*args, &block)
    super

    # Make sure the WSDL is properly maintained!
    @wsdl = File.read(File.expand_path(File.join(File.dirname(__FILE__), 'barcode_service.wsdl'))).gsub(%r{http://localhost:9998}, "http://#{host}:#{port}")
  end

  def barcodes
    @barcodes ||= []
  end

  def clear
    @barcodes = []
    @printed_labels = []
  end

  def barcode(barcode)
    self.barcodes.push(barcode)
  end

  def next_barcode!
    self.barcodes.shift or raise StandardError, "No more values set!"
  end

  def service
    Service
  end

  # Barcode printing related
  def printed_labels()
    @printed_labels ||= []
  end

  def printed_labels!()
    labels = printed_labels
    clear_printed_labels!
    labels
  end

  def clear_printed_labels!()
    @printed_labels=[]
  end

  def first_printed_labels!()
    @printed_labels.shift
  end
  def last_printed_label!()
    @printed_labels.pop
  end

  class Service < FakeSinatraService::Base
    get('/barcode_service.wsdl') do
      headers('Content-Type' => 'text/xml')
      body(FakeBarcodeService.instance.wsdl)
    end

    # Hand crafted SOAP envelope to say success!
    post('/barcode_service') do
      data = request.body.map
      FakeBarcodeService.instance.printed_labels << data
      status(200)
      headers('Content-Type' => 'text/xml')
      body(%Q{<?xml version="1.0"?>
        <soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
          <soap:Body>
            <m:printLabels xmlns:m="urn:Barcode/Service" soap:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
              <m:printLabelsReturn>true</m:printLabelsReturn>
            </m:printLabels>
          </soap:Body>
        </soap:Envelope>
      })
    end

    post('/plate_barcode_service/plate_barcodes.xml') do
      barcode = FakeBarcodeService.instance.next_barcode!
      headers('Content-Type' => 'text/xml')
      body(%Q{<plate_barcode><id>42</id><name>Barcode #{barcode}</name><barcode>#{barcode}</barcode></plate_barcode>})
    end
  end
end

FakeBarcodeService.install_hooks(self, '@barcode-service')
