# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2014,2015,2016 Genome Research Ltd.
require_dependency 'tube/purpose'

class LibraryTube < Tube
  include Api::LibraryTubeIO::Extensions
  include ModelExtensions::LibraryTube

  def is_sequenceable?
    true
  end

  def library_prep?
    true
  end

  def can_be_created?
    true
  end

  scope :include_tag, -> { includes(aliquots: { tag: [:uuid_object, { tag_group: :uuid_object }] }) }

  def sorted_tags_for_select
    get_tag.tag_group.tags.order(:map_id).pluck(:name, :id)
  end

  def self.stock_asset_type
    StockLibraryTube
  end

  def self.stock_asset_purpose
    Tube::Purpose.stock_library_tube
  end

  def specialized_from_manifest=(attributes)
    if first_update?
      # library_id is assigned on aliquot creation in `tube_sample_creation` method
      # in sample_manifest `library` and `multiplexed library` behaviours
      # library_id should be removed from here at some point (20/04/2017)
      aliquots.first.update_attributes!(attributes.merge(library_id: id))
      requests.each(&:manifest_processed!)
    end
  end

  def first_update?
    external_library_creation_request = requests.find_by(sti_type: 'ExternalLibraryCreationRequest')
    external_library_creation_request && external_library_creation_request.allow_library_update?
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
