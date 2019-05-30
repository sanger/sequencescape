require_dependency 'tube/purpose'

class LibraryTube < Tube
  include Api::LibraryTubeIO::Extensions
  include ModelExtensions::LibraryTube

  self.library_prep = true
  self.sequenceable = true

  scope :include_tag, -> { includes(aliquots: { tag: [:uuid_object, { tag_group: :uuid_object }] }) }

  def self.stock_asset_type
    StockLibraryTube
  end

  def self.stock_asset_purpose
    Tube::Purpose.stock_library_tube
  end

  def specialized_from_manifest=(_attributes)
    external_library_creation_requests.each(&:manifest_processed!)
  end

  def library_information
    tag  = aliquots.first.tag
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

  def library_information=(library_information)
    library_information[:tag]  = find_tag(library_information[:tag])
    library_information[:tag2] = find_tag(library_information[:tag2]) if library_information[:tag2]

    self.specialized_from_manifest = library_information
  end

  def library_source_plates
    purpose.try(:library_source_plates, self) || []
  end

  def find_tag(tag_info)
    tag_group = Uuid.with_resource_type('TagGroup').include_resource.find_by!(external_id: tag_info['tag_group']).resource
    tag_group.tags.find_by!(map_id: tag_info['tag_index'])
  end
  private :find_tag

  extend Asset::Stock::CanCreateStockAsset
end

require_dependency 'spiked_buffer'
