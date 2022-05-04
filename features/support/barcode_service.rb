# frozen_string_literal: true

require 'singleton'

class FakeBarcodeService # rubocop:todo Style/Documentation
  include Singleton

  # Ensure that the configuration is maintained, otherwise things start behaving badly
  # when it comes to the features.
  def self.install_hooks(target, tags)
    target.instance_eval do
      Before(tags) do |_scenario|
        plate_barcode_url = configatron.baracoda_api
        Rails.logger.debug { "Mocking barcode service #{plate_barcode_url}/barcodes/SQPD/new" }
        stub_request(:post, "#{plate_barcode_url}/barcodes/SQPD/new").to_return do
          barcode_record = FakeBarcodeService.instance.next_barcode!
          {
            headers: {
              'Content-Type' => 'text/json'
            },
            status: 201,
            body: barcode_record.to_json
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

  def barcode(barcode, format=nil)
    barcodes.push({barcode: barcode, format: format})
  end

  def next_barcode!
    barcodes.shift or raise StandardError, 'No more values set!'
  end

  def next_matching_barcode_start(barcode, count)
    # Find the most recent similar barcode
    plate_barcode = Barcode.where("barcode like '#{barcode}%'").order(:id).last.barcode
    # match the barcode found and return the next valid value
    matching = plate_barcode.match(/([^-]*-[^-]*)-(\d*)/)
    [matching[1], (matching[2].to_i + 1),  (matching[2].to_i + count)]
  end

  def parent_barcode_start(parent_barcode, count)
    matching = parent_barcode.match(/([^-]*-[^-]*)-(\d*)/)
    return next_matching_barcode_start(matching[1], count) if matching
    [parent_barcode, 1, count]
  end

  def child_barcode_records(parent_barcode, count)
    barcode, start, finish = parent_barcode_start(parent_barcode, count)
    (start..finish).to_a.map do |value| 
      { barcode: "#{barcode}-#{value}" }
    end
  end

  def mock_child_barcodes(parent_barcode, count)
    plate_barcode_url = configatron.baracoda_api
    Rails.logger.debug { "Mocking child barcode service #{plate_barcode_url}/child-barcodes/new" }
    WebMock.stub_request(:post, "#{plate_barcode_url}/child-barcodes/new").with(body: {
      barcode: parent_barcode, count: count
    }).to_return do
      {
        headers: {
          'Content-Type' => 'text/json'
        },
        status: 201,
        body: { barcodes: child_barcode_records(parent_barcode, count) }.to_json
      }
    end
  end
end

FakeBarcodeService.install_hooks(self, '@barcode-service')
