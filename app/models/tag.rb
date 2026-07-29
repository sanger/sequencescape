# frozen_string_literal: true
# A Tag is a short, know sequence of DNA which gets applied to a sample.
# The tag remains attached through subsequent processing, and means that it is
# possible to identify the origin of a sample if multiple samples are subsequently
# pooled together.
# Tags are sometimes referred to as barcodes by our users.
# Tag is stored on aliquot, and an individual aliquot can have two tags
# identified as tag and tag2, these may also be known as i7 and i5 respectively.
class Tag < ApplicationRecord
  module Associations
    def untag!
      aliquots.first.try(:update!, tag: nil)
    end
  end

  include Api::TagIo::Extensions

  self.per_page = 500
  include Uuid::Uuidable

  belongs_to :tag_group
  has_many :aliquots
  has_many :assets, through: :aliquots, source: :receptacle
  has_many :requests, -> { distinct }, through: :assets

  broadcast_with_warren

  scope :sorted, -> { order(:map_id) }

  def name
    "Tag #{map_id}"
  end

  # Connects a tag instance to the specified asset
  def tag!(asset)
    asset.attach_tag(self)
  end

  # Allows the application of multiple tags to an aliquot
  def multitag!(asset) # rubocop:todo Metrics/MethodLength
    raise StandardError, 'Cannot tag an empty asset' if asset.aliquots.empty?

    asset
      .aliquots
      .group_by(&:sample_id)
      .each do |_sample_id, aliquots|
        if aliquots.first.no_tag1?
          aliquots.first.update(tag: self)
        else
          asset.aliquots << aliquots.first.dup(tag: self, receptacle: asset)
        end
      end
  end

  # Map id is converted to a string here for consistency with elsewhere in the api.
  def summary
    { tag_group: tag_group.name, tag_index: map_id.to_s }
  end
end
