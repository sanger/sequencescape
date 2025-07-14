# frozen_string_literal: true
require 'rails_helper'

RSpec.describe LabelPrinter::Label::BatchTube, type: :model do
  subject(:batch_tube) { described_class.new(options) }

  context 'when target_asset is a lane' do
    let(:lane) { create(:lane).tap { |lane| lane.labware.parents << tube } }
    let(:tube) { create(:multiplexed_library_tube) }
    let(:request) { create(:sequencing_request, target_asset: lane, asset: tube.receptacle) }
    let(:batch) { create(:batch).tap { |batch| batch.requests << request } }
    let(:printable) { { request.id => 'on' } }
    let(:options) { { count: '1', printable: printable, batch: batch, stock: false } }
    let(:date_today) { Date.new(2025, 7, 9) }

    before do
      travel_to date_today
    end

    it 'returns the parent tube' do
      expect(batch_tube.tubes.first).to eq tube
    end

    it 'returns the label for the parent tube' do
      label = {
        first_line: tube.name_for_label,
        second_line: tube.barcode_number,
        third_line: Time.zone.today.strftime('%e-%^b-%Y'),
        round_label_top_line: tube.prefix,
        round_label_bottom_line: tube.barcode_number,
        barcode: tube.machine_barcode,
        label_name: 'main_label'
      }
      expect(batch_tube.labels.first).to eq label
    end
  end
end
