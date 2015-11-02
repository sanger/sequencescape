#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2011,2012,2014 Genome Research Ltd.
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

  named_scope :include_tag, :include => { :aliquots => { :tag => [ :uuid_object, { :tag_group => :uuid_object } ] } }

  def sorted_tags_for_select
    self.get_tag.tag_group.tags.sort{ |a,b| a.map_id <=> b.map_id }.collect { |t| [t.name, t.id] }
  end

  # A library tube is created with request options that come from the request in which it is the target asset.
  def created_with_request_options
    creation_request.try(:request_options_for_creation) || {}
  end

  def self.stock_asset_type
    StockLibraryTube
  end

  def self.stock_asset_purpose
    Tube::Purpose.stock_library_tube
  end

  def specialized_from_manifest=(attributes)
    aliquots.first.update_attributes!(attributes.merge(:library_id => self.id))
    requests.map(&:manifest_processed!)
  end

  def library_information
    tag  = aliquots.first.tag
    tag2 = aliquots.first.tag2
    {
      :library_type => aliquots.first.library_type,
      :insert_size_from => aliquots.first.insert_size_from,
      :insert_size_to   => aliquots.first.insert_size_to
    }.tap do |tag_hash|
      tag_hash.merge!(:tag=>tag.summary) if tag
      tag_hash.merge!(:tag2=>tag2.summary) if tag2
    end
  end

  def library_information=(library_information)

    library_information[:tag]  = find_tag(library_information[:tag])
    library_information[:tag2] = find_tag(library_information[:tag2]) if library_information[:tag2]

    self.specialized_from_manifest= library_information
  end

  def find_tag(tag_info)
    tag_group = Uuid.with_resource_type('TagGroup').include_resource.find_by_external_id!(tag_info['tag_group']).resource
    tag_group.tags.find_by_map_id!(tag_info['tag_index'])
  end
  private :find_tag

  extend Asset::Stock::CanCreateStockAsset
end
