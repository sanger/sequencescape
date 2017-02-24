# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'singleton'
class FakeBarcodeService
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
            headers: { 'Content-Type' => 'text/xml' },
            body: "<plate_barcode><id>42</id><name>Barcode #{barcode}</name><barcode>#{barcode}</barcode></plate_barcode>"
          }
        end
      end

      After(tags) do |_scenario|
        FakeBarcodeService.instance.clear
      end
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
