# frozen_string_literal: true

#
# The aliquot indexer is passed a {Receptacle} (usually a {Lane}) and
# generates an {AliquotIndex index} for all aliquots. This is a unique index that NPG
# use to identify deplexed sequencing data. It replaces the previous role of
# the map id of tag 1 (the i7) and allows a single identifier to be used to
# represent both indices.
# - Aliquots are sorted by the tag_2 map id, then the tag_1 map id.
# - Tags associated with the PhiX tube are excluded. This includes the default
#   phix tag index (configatron.phix_tag.tag_map_id) [888 at time of writing]
#   as well as the actual index if they happen to differ.
class AliquotIndexer
  attr_reader :lane, :aliquots

  module AliquotScopes
    def self.included(base)
      base.class_eval do
        scope :sorted_for_indexing, -> { includes(%i[tag tag2]).reorder('tag2s_aliquots.map_id ASC, tags.map_id ASC') }
      end
    end
  end

  # Include in Receptacles to allow idempotent indexing by calling index_aliquots
  module Indexable
    def index_aliquots
      # Skip indexing if already present. Makes the call idempotent and also
      # reduces the downtime required for the initial migration. Race conditions
      # are unlikely, and will be pretty harmless if they do occur.
      AliquotIndexer.index(self) if aliquot_indicies.blank?
    end
  end

  #
  # Generate an aliquot index for lane
  # @param lane [Receptacle] The receptacle to index. Probably a lane.
  #
  # @return [Bool] Returns true if the index was successful
  def self.index(lane)
    new(lane).index
  end

  def initialize(lane)
    @lane = lane
    @index = 0
  end

  # The actual index of the PhiX used in the lane.
  # Note: PhiX isn't actually present as an aliquot within the lane, instead the PhiX
  # tube is associated with the Lane as a parent asset.
  # @return [Integer] map_id of the PhiX in the lane.
  def phix_map_id
    return nil if lane.spiked_in_buffer.blank?

    @phix_map_id ||= lane.spiked_in_buffer.primary_aliquot.tag.try(:map_id)
  end

  # Returns all aliquots due to be indexed.
  # @return [Array<Aliquot>] An sorted array of aliquots to index
  def aliquots
    @aliquots ||= lane.aliquots.sorted_for_indexing
  end

  def index
    @lane.aliquot_indicies.build(aliquots.map { |a| { aliquot: a, aliquot_index: next_index } })
    @lane.save
  end

  private

  # The next index suitable for the aliquot (skips those associated with PhiX)
  def next_index
    @index += 1
    next_index if [phix_map_id, configatron.phix_tag.tag_map_id].include?(@index)
    @index
  end
end
