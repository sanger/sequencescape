# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class Tag < ActiveRecord::Base
  module Associations
    def untag!
      aliquots.first.try(:update_attributes!, tag: nil)
    end
  end

  include Api::TagIO::Extensions

  self.per_page = 500
  include Uuid::Uuidable

  belongs_to :tag_group
  has_many :aliquots
  has_many :assets, through: :aliquots, source: :receptacle
  has_many :requests, ->() { distinct }, through: :assets

  scope :sorted, ->() { order('map_id ASC') }

  def name
    "Tag #{map_id}"
  end

  # Connects a tag instance to the specified asset
  def tag!(asset)
    raise StandardError, 'Cannot tag an empty asset'   if asset.aliquots.empty?
    raise StandardError, 'Cannot tag multiple samples' if asset.aliquots.size > 1
    asset.aliquots.first.update_attributes!(tag: self)
  end

  # Allows the application of multiple tags to an aliquot
  def multitag!(asset)
    raise StandardError, 'Cannot tag an empty asset'   if asset.aliquots.empty?
    asset.aliquots.group_by { |aliquot| aliquot.sample_id }.each do |_sample_id, aliquots|
      new_aliquot = aliquots.first.untagged? ? aliquots.first : aliquots.first.dup
      # dup automatically unsets receptacle, so we reallocate it here.
      new_aliquot.receptacle = asset
      new_aliquot.tag = self
      new_aliquot.save!
    end
  end

  # Map id is converted to a string here for consistency with elsewhere in the api.
  def summary
    {
      tag_group: tag_group.name,
      tag_index: map_id.to_s
    }
  end
end
