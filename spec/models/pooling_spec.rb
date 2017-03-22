require 'rails_helper'

describe Pooling do
  let(:empty_lb_tube) { create :empty_library_tube, barcode: 1 }
  let(:untagged_lb_tube1) { create :library_tube, barcode: 2 }
  let(:untagged_lb_tube2) { create :library_tube, barcode: 3 }
  let(:tagged_lb_tube1) { create :tagged_library_tube, barcode: 4 }
  let(:tagged_lb_tube2) { create :tagged_library_tube, barcode: 5 }
  let(:mx_tube) { create :multiplexed_library_tube, barcode: 6 }

  it 'should not be valid without source_assets' do
    pooling = Pooling.new(barcodes: [])
    expect(pooling.valid?).to be false
    expect(pooling.errors.full_messages).to include 'Source assets were not scanned or were not found in sequencescape'
  end

  it 'should not be valid if tubes are not in sqsc, if tubes do not have at least one aliquot or if there is a tag clash' do
    barcodes = [-1, -2, empty_lb_tube.ean13_barcode, untagged_lb_tube1.ean13_barcode, untagged_lb_tube2.ean13_barcode]
    pooling = Pooling.new(barcodes: barcodes)
    expect(pooling.valid?).to be false
    expect(pooling.errors.messages.count).to eq 2
    expect(pooling.errors.full_messages).to include 'Source assets with barcode(s) -1, -2 were not found in sequencescape'
    expect(pooling.errors.full_messages).to include "Source assets with barcode(s) #{empty_lb_tube.ean13_barcode} do not have any aliquots"
    expect(pooling.errors.full_messages).to include 'Tags combinations are not unique'
  end

  context 'execute' do
    before(:each) do
      @barcodes = [tagged_lb_tube1.ean13_barcode, tagged_lb_tube2.ean13_barcode, untagged_lb_tube1.ean13_barcode, mx_tube.ean13_barcode]
      2.times { |_n| create(:single_tagged_aliquot, receptacle: mx_tube) }
    end

    it 'should be valid if tubes are in sqsc, have at least 1 aliquot and there is no tag clash' do
      pooling = Pooling.new(barcodes: @barcodes)
      expect(pooling.valid?).to be true
    end

    it 'should create only standard mx tube if stock is not required' do
      pooling = Pooling.new(barcodes: @barcodes)
      pooling.execute
      expect(pooling.stock_mx_tube.present?).to be false
      expect(pooling.standard_mx_tube.aliquots.count).to eq 5
    end

    it 'should create stock and standard mx tube if required' do
      pooling = Pooling.new(barcodes: @barcodes, stock_mx_tube_required: true)
      pooling.execute
      expect(pooling.stock_mx_tube.aliquots.count).to eq 5
      expect(pooling.standard_mx_tube.aliquots.count).to eq 5
    end

    it 'should execute print_job if barcode printer is provided' do
      barcode_printer = create :barcode_printer
      LabelPrinter::PmbClient.stub(:get_label_template_by_name) { { 'data' => [{ 'id' => 15 }] } }
      pooling = Pooling.new(barcodes: @barcodes, barcode_printer: barcode_printer.name)
      expect(RestClient).to receive(:post)
      pooling.execute
      expect(pooling.print_job_required?).to be true
    end
  end
end
