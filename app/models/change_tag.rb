# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module ChangeTagException
  class MissingTag < RuntimeError
  end
  class MissingLibraryTube < RuntimeError
  end
end

class ChangeTag
  attr_accessor :library_tubes
  attr_accessor :library_tube_ids

  def initialize(options = {})
    parse_library_tube_ids(options[:library_tube_ids])
    lookup_library_tubes
  end

  def validate!
    raise ChangeTagException::MissingLibraryTube if library_tubes.include?(nil)
    tubes_have_tags!
  end

  def self.update_tags(library_tubes_to_tags)
    ActiveRecord::Base.transaction do
      library_tubes_to_tags.each do |library_tube_id, tag_id|
        tube = LibraryTube.find(library_tube_id)
        new_tag = Tag.find(tag_id)
        tube.aliquots.first.descendants(true).map do |aliquot|
          aliquot.update_attributes!(tag: new_tag)
        end
      end
    end
  end

  protected

  def parse_library_tube_ids(library_tube_ids_string)
    @library_tube_ids = []
    library_tube_ids_string.scan(/\d+/).each do |library_tube_id|
      library_tube_ids << library_tube_id
    end
  end

  def lookup_library_tubes
    @library_tubes = []
    library_tube_ids.each do |asset_id|
      library_tubes << asset_from_id(asset_id)
    end
  end

  def asset_from_id(asset_id)
    Asset.find_by(id: asset_id) || Asset.find_by(barcode: asset_id)
  end

  def tubes_have_tags!
    library_tubes.each do |library_tube|
      raise ChangeTagException::MissingTag if library_tube.get_tag.nil?
    end
  end
end
