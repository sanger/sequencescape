# frozen_string_literal: true
module Dev
  module PlateBarcode
    # When in development mode we were receiving concurrent requests for creating a barcode
    # which produced a race condition where all concurrent requests were obtaining the same barcode.
    # To avoid it this module implements a cache of barcodes so it should be able to support
    # up to MAX_SIZE_CACHE concurrent requests which we expect should be enough for
    # development.
    module CacheBarcodes
      # Obtains a new barcode and if the obtained barcode was obtained before (if it was cached)
      # it will retry and obtain a new barcode
      def dev_cache_get_next_barcode
        pos = 1
        next_barcode = nil
        loop do
          next_barcode = (Barcode.sequencescape22.order(id: :desc).first&.number || 9000) + pos
          pos += 1
          break unless barcode_in_cache?(next_barcode)
        end
        cache_barcode(next_barcode)
        next_barcode
      end

      MAX_SIZE_CACHE = 100

      # Cache stored in a class property (in PlateBarcode)
      def data_cache
        @data_cache ||= []
      end

      def reset_cache
        @data_cache = []
      end

      # Avoids the cache to grow out of the cache limits
      def resize_cache
        @data_cache = data_cache.drop(1) if data_cache.length >= MAX_SIZE_CACHE
      end

      def cache_barcode(barcode)
        resize_cache

        data_cache.push(barcode)
      end

      def barcode_in_cache?(barcode)
        data_cache.include?(barcode)
      end
    end
  end
end
