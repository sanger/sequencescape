# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LabelPrinter::Label::BatchPlateAmp, type: :model do
  subject(:batch_plate_amp) { described_class.new(options) }

  context 'with one tube' do
    let(:tube) { create(:multiplexed_library_tube) }

    let(:lane) { create(:lane).tap { |lane| lane.labware.parents << tube } }
    let(:request) { create(:sequencing_request, target_asset: lane, asset: tube.receptacle) }
    let(:batch) { create(:batch).tap { |batch| batch.requests << request } }

    let(:printable) { { tube.human_barcode => 'on' } }
    let(:options) { { count: '1', printable: printable, batch: batch, stock: false } }
    let(:date_today) { Date.new(2025, 7, 9) }

    before do
      travel_to date_today
    end

    it 'returns the correct label format' do
      expected_barcode = "#{batch.id}_#{tube.human_barcode}"

      label = {
        top_left: ' 9-JUL-2025', # TODO: why is there a leading space?
        bottom_left: expected_barcode,
        top_right: nil,
        bottom_right: nil,
        top_far_right: nil,
        barcode: expected_barcode,
        label_name: 'main_label'
      }
      expect(batch_plate_amp.labels.first).to eq label
    end
  end
end
