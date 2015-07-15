#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015 Genome Research Ltd.
class AliquotIndexer

  attr_reader :lane, :aliquots

  module AliquotScopes
    def self.included(base)
      base.class_eval do
        named_scope :sorted_for_indexing, { :joins => [:tag,:tag2], :order => 'tag2s_aliquots.map_id ASC, tags.map_id ASC' }
      end
    end
  end

  module Indexable
    def index_aliquots
      # Skip indexing if already present. Makes the call idempotent and also
      # reduces the downtime required for the initial migration. Race conditions
      # are unlikely, and will be pretty harmless if they do occur.
      AliquotIndexer.index(self) unless aliquot_indicies.present?
    end
  end

  def self.index(lane)
    new(lane).index
  end

  def initialize(lane)
    @lane = lane
    @index = 0
  end

  def phix_map_id
    return nil unless lane.spiked_in_buffer.present?
    @phix_map_id ||= lane.spiked_in_buffer.primary_aliquot.tag.try(:map_id)
  end

  def aliquots
    @aliquots ||= lane.aliquots
  end

  def next_index
    @index += 1
    next_index if [phix_map_id,configatron.phix_tag.tag_map_id].include?(@index)
    @index
  end

  def index
    @lane.aliquot_indicies.build(aliquots.map {|a,i| {:aliquot=>a, :aliquot_index => next_index } })
    @lane.save
  end
end
