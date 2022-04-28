# frozen_string_literal: true

require 'singleton'
class FakeBarcodeService # rubocop:todo Style/Documentation
  include Singleton

  # Ensure that the configuration is maintained, otherwise things start behaving badly
  # when it comes to the features.
  def self.install_hooks(target, tags)
    target.instance_eval do
      Before(tags) do |_scenario|
        plate_barcode_url = configatron.plate_barcode_service
        stub_request(:post, "#{plate_barcode_url}plate_barcodes.xml").to_return do
          barcode = FakeBarcodeService.instance.next_barcode!
          {
            headers: {
              'Content-Type' => 'text/xml'
            },
            body:
              "<plate_barcode><id>42</id><name>Barcode #{barcode}</name><barcode>#{barcode}</barcode></plate_barcode>"
          }
        end
      end

      After(tags) { |_scenario| FakeBarcodeService.instance.clear }
    end
  end

  def barcodes
    @barcodes ||= []
  end

  def clear
    @barcodes = []
  end

  def barcode(barcode)
    barcodes.push(barcode)
  end

  def next_barcode!
    barcodes.shift or raise StandardError, 'No more values set!'
  end
end

FakeBarcodeService.install_hooks(self, '@barcode-service')
