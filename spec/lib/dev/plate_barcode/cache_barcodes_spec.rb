# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Dev::PlateBarcode::CacheBarcodes do
  describe '#dev_cache_get_next_barcode' do
    let(:my_class) { Class.new { extend Dev::PlateBarcode::CacheBarcodes } }
    let(:instance) { my_class.new }

    context 'when getting new barcodes' do
      before { my_class.reset_cache }

      it 'gets different barcodes on each call' do
        expect(my_class.dev_cache_get_next_barcode).to eq(9001)
        expect(my_class.dev_cache_get_next_barcode).to eq(9002)
        expect(my_class.dev_cache_get_next_barcode).to eq(9003)
      end
    end

    context 'with the cache management' do
      before { my_class.reset_cache }

      it 'cache grows with every new barcode' do
        expect { my_class.dev_cache_get_next_barcode }.to change { my_class.data_cache.length }.by(1)
        expect do
          my_class.dev_cache_get_next_barcode
          my_class.dev_cache_get_next_barcode
          my_class.dev_cache_get_next_barcode
        end.to change { my_class.data_cache.length }.by(3)
      end

      it 'does not grow over the max size' do
        pos = 0
        while pos < Dev::PlateBarcode::CacheBarcodes::MAX_SIZE_CACHE
          my_class.dev_cache_get_next_barcode
          pos += 1
        end

        expect do
          my_class.dev_cache_get_next_barcode
          my_class.dev_cache_get_next_barcode
          my_class.dev_cache_get_next_barcode
        end.not_to(change { my_class.data_cache.length })
      end
    end
  end
end
