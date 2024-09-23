# frozen_string_literal: true

require 'rails_helper'

describe Pooling, :poolings do
  let(:empty_lb_tube) { create :empty_library_tube, barcode: 1 }
  let(:untagged_lb_tube1) { create :library_tube, barcode: 2 }
  let(:untagged_lb_tube2) { create :library_tube, barcode: 3 }
  let(:tagged_lb_tube1) { create :tagged_library_tube, barcode: 4 }
  let(:tagged_lb_tube2) { create :tagged_library_tube, barcode: 5 }
  let(:mx_tube) { create :multiplexed_library_tube, barcode: 6 }
  let(:stock_mx_tube_required) { false }
  let(:barcode_printer_option) { nil }
  let(:pooling) do
    described_class.new(
      barcodes:,
      stock_mx_tube_required:,
      barcode_printer: barcode_printer_option,
      count: 1
    )
  end

  context 'without source assets' do
    let(:barcodes) { [] }

    it 'is not valid without source_assets' do
      expect(pooling).not_to be_valid
      expect(
        pooling.errors.full_messages
      ).to include 'Source assets were not scanned or were not found in Sequencescape'
    end
  end

  context 'with a series of invalid assets' do
    let(:barcodes) do
      ['-1', '-2', empty_lb_tube.ean13_barcode, untagged_lb_tube1.human_barcode, untagged_lb_tube2.ean13_barcode]
    end

    it 'is not valid if tubes are not in sqsc, if tubes do not have at least one aliquot or if there is a tag clash' do
      expect(pooling).not_to be_valid
      expect(pooling.errors.messages.count).to eq 2
      expect(
        pooling.errors.full_messages
      ).to include 'Source assets with barcode(s) -1, -2 were not found in Sequencescape'
      expect(
        pooling.errors.full_messages
      ).to include "Source assets with barcode(s) #{empty_lb_tube.ean13_barcode} do not have any aliquots"
      expect(pooling.errors.full_messages).to include 'Tags combinations are not compatible and result in a tag clash'
    end
  end

  describe '#execute' do
    let(:barcodes) do
      [
        tagged_lb_tube1.machine_barcode,
        tagged_lb_tube2.machine_barcode,
        untagged_lb_tube1.machine_barcode,
        mx_tube.machine_barcode
      ]
    end

    before { create_list(:single_tagged_aliquot, 2, receptacle: mx_tube) }

    it 'is valid if tubes are in sqsc, have at least 1 aliquot and there is no tag clash' do
      expect(pooling).to be_valid
    end

    it 'creates only standard mx tube if stock is not required' do
      expect(pooling.execute).to be true
      expect(pooling.stock_mx_tube.present?).to be false
      expect(pooling.standard_mx_tube.aliquots.count).to eq 5
      expect(pooling.message).to eq(
        notice: "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} "
      )
    end

    it 'sets up child relationships' do
      expect(pooling.execute).to be true
      expect(Labware.with_barcode(barcodes).all? { |l| l.children.include?(pooling.standard_mx_tube) }).to be true
    end

    context 'when stock_mx_tube_required is true' do
      let(:stock_mx_tube_required) { true }

      it 'creates stock and standard mx tube' do
        expect(pooling.execute).to be true
        expect(pooling.stock_mx_tube.aliquots.count).to eq 5
        expect(pooling.standard_mx_tube.aliquots.count).to eq 5
        expect(pooling.message).to eq(
          notice:
            # rubocop:todo Layout/LineLength
            "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} and stock_mx_tube #{Tube.last(2).first.human_barcode} "
          # rubocop:enable Layout/LineLength
        )
      end

      it 'sets up child relationships', :aggregate_failures do
        expect(pooling.execute).to be true
        input_tubes = Labware.with_barcode(barcodes)
        expect(input_tubes.all? { |l| l.children.include?(pooling.stock_mx_tube) }).to be true
        expect(input_tubes.all? { |l| l.children.include?(pooling.standard_mx_tube) }).to be false
        expect(pooling.stock_mx_tube.children).to include(pooling.standard_mx_tube)
      end
    end

    # LibraryTubes created as part of an MX library manifest have two associated requests,
    # the CreateAssetRequest and the ExternalLibraryCreationRequest. When the TransferRequest
    # is created, it was attempting to associate itself with one of these requests, and then
    # failing to disambiguate between them.
    context 'when the source tubes are from an mx library manifest' do
      before do
        create :create_asset_request, asset: tagged_lb_tube1.receptacle
        create(:external_multiplexed_library_tube_creation_request, asset: tagged_lb_tube1.receptacle)
      end

      let(:stock_mx_tube_required) { true }

      it 'creates stock and standard mx tube' do
        expect(pooling.execute).to be true
      end
    end

    context 'when a barcode printer is provided' do
      let(:barcode_printer) { create :barcode_printer }
      let(:barcode_printer_option) { barcode_printer.name }

      it 'executes print_job' do
        allow(LabelPrinter::PmbClient).to receive(:get_label_template_by_name).and_return('data' => [{ 'id' => 15 }])
        expect(RestClient).to receive(:post)
        expect(pooling.execute).to be true
        expect(pooling.print_job_required?).to be true
        expect(pooling.message).to eq(
          notice:
            # rubocop:todo Layout/LineLength
            "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} Your 1 label(s) have been sent to printer #{barcode_printer.name}"
          # rubocop:enable Layout/LineLength
        )
      end

      it 'returns correct message if something is wrong with pmb' do
        expect(pooling.execute).to be true
        expect(pooling.message).to eq(
          error: 'Printmybarcode service is down',
          notice: "Samples were transferred successfully to standard_mx_tube #{Tube.last.human_barcode} "
        )
      end
    end
  end

  context 'when samples have the same tags' do
    let(:barcodes) { [tagged_lb_tube1.machine_barcode, tagged_lb_tube2.machine_barcode] }

    before do
      # set the tags in the second tube to be the same as the first, to create a tag clash
      tag1 = tagged_lb_tube1.aliquots.first.tag
      tag2 = tagged_lb_tube1.aliquots.first.tag2
      tagged_lb_tube2.aliquots.first.update!(tag: tag1, tag2:)
    end

    it 'is not valid due to the tag clash' do
      expect(pooling).not_to be_valid
    end

    # Tag depth is an identifier added to each aliquot in a receptacle
    #   to indicate that they can be distinguished, despite having the same tags.
    # It was introduced for the Cardinal pipeline, where they can be distinguished
    #   due to having been previously sequenced.
    # Therefore, if the tag depths are different, there should be no 'tag clash'.
    context 'when samples have same tags but different tag depths' do
      before do
        tagged_lb_tube1.aliquots.first.update!(tag_depth: 2)
        tagged_lb_tube2.aliquots.first.update!(tag_depth: 3)
      end

      it 'is valid because the tag depths are different' do
        expect(pooling).to be_valid
      end
    end
  end
end
