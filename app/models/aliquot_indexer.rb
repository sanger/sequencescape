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

  def self.index(lane)
    new(lane).index
  end

  def initialize(lane)
    @lane = lane
  end

  def aliquots
    @aliquots ||= lane.aliquots
  end

  def index
    @lane.aliquot_indicies.build(aliquots.each_with_index.map {|a,i| {:aliquot=>a, :aliquot_index => i+1 } })
    @lane.save
  end
end
