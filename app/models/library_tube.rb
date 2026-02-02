# frozen_string_literal: true

class LibraryTube < Tube
  include Api::LibraryTubeIo::Extensions
  include ModelExtensions::LibraryTube
  include Asset::SharedLibraryTubeBehaviour

  def self.stock_asset_type
    StockLibraryTube
  end

  def self.stock_asset_purpose
    Tube::Purpose.stock_library_tube
  end

  def library_information # rubocop:todo Metrics/AbcSize
    tag = aliquots.first.tag
    tag2 = aliquots.first.tag2
    {
      library_type: aliquots.first.library_type,
      insert_size_from: aliquots.first.insert_size_from,
      insert_size_to: aliquots.first.insert_size_to
    }.tap do |tag_hash|
      tag_hash[:tag] = tag.summary if tag
      tag_hash.merge!(tag2: tag2.summary) if tag2
    end
  end

  extend Asset::Stock::CanCreateStockAsset
end
