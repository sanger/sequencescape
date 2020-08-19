# frozen_string_literal: true

require 'spec_helper'
require './app/views/plate_picks/batches_json'

RSpec.describe PlatePicks::BatchesJson, type: :view do
  describe '#to_json' do
    subject { described_class.new(1, pick_info, plate_info).to_json }

    let(:pick_info) do
      { 'DN12345' => {
        1 => [
          { 'DN12345' => 1 },
          { 'DN12345' => 1, 'DN12346' => 3, 'DN12347' => 2 }
        ],
        2 => [
          { 'DN12345' => 1 },
          { 'DN12348' => 1, 'DN12349' => 3, 'DN12350' => 2 }
        ]
      } }
    end

    let(:plate_info) do
      {
        'DN12345' => { barcode: 'DN12345', batches: ['1'] },
        'DN12346' => { barcode: 'DN12346', batches: ['1'] },
        'DN12347' => { barcode: 'DN12347', batches: ['1'] },
        'DN12348' => { barcode: 'DN12348', batches: ['1'] },
        'DN12349' => { barcode: 'DN12349', batches: ['1'] },
        'DN12350' => { barcode: 'DN12350', batches: ['1'] }
      }
    end

    let(:expected_output) do
      { batch: {
        id: '1',
        picks: [
          {
            name: '1:DN12345 1 of 2',
            plates: [
              { barcode: 'DN12345', batches: ['1'] },
              { barcode: 'DN12346', batches: ['1'] },
              { barcode: 'DN12347', batches: ['1'] }
            ]
          },
          {
            name: '1:DN12345 2 of 2',
            plates: [
              { barcode: 'DN12348', batches: ['1'] },
              { barcode: 'DN12349', batches: ['1'] },
              { barcode: 'DN12350', batches: ['1'] }
            ]
          }
        ]
      } }
    end

    it { is_expected.to eq expected_output }
  end
end
