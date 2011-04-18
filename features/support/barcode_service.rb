require File.expand_path(File.join(File.dirname(__FILE__), 'fake_sinatra_service.rb'))

class FakeBarcodeService < FakeSinatraService
  attr_reader :wsdl

  def initialize(*args, &block)
    super
    configatron.plate_barcode_service = "http://#{host}:#{port}/plate_barcode_service/"
    configatron.barcode_service_url   = "http://#{host}:#{port}/barcode_service.wsdl"

    # Make sure plate barcoding is properly hooked up to the service
    PlateBarcode.site = configatron.plate_barcode_service

    # Make sure the WSDL is properly maintained!
    @wsdl = File.read(File.expand_path(File.join(File.dirname(__FILE__), 'barcode_service.wsdl'))).gsub(%r{http://localhost:9998}, "http://#{host}:#{port}")
  end

  def barcodes
    @barcodes ||= []
  end

  def clear
    @barcodes = []
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

  class Service < FakeSinatraService::Base
    get('/barcode_service.wsdl') do
      headers('Content-Type' => 'text/xml')
      body(FakeBarcodeService.instance.wsdl)
    end

    # Hand crafted SOAP envelope to say success!
    post('/barcode_service') do
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
