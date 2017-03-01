# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

module Aliquot::Remover
  class AliquotRecord
    # We can't use the aliquot itself, as it will have been destroyed by
    # the time we want to look at it. The aliquot record mimics
    # an aliquot in the comparison functions

    attr_reader :tag_id, :sample_id, :library_id, :bait_library_id, :tag2_id

    def initialize(aliquot)
      @tag_id = aliquot.tag_id
      @sample_id = aliquot.sample_id
      @library_id = aliquot.library_id
      @bait_library_id = aliquot.bait_library_id
      @tag2_id = aliquot.tag2_id
    end

    def tagged?
      !untagged?
    end

    def untagged?
      tag_id.nil? or (tag_id == Aliquot::UNASSIGNED_TAG)
    end

    def no_tag2?
      tag2_id.nil? or (tag2_id == Aliquot::UNASSIGNED_TAG)
    end
  end

  def remove_downstream_aliquots
    # On the target asset of the failed request.
    ActiveRecord::Base.transaction do
      target_aliquots = aliquots.map { |aliquot| AliquotRecord.new(aliquot) }
      on_downstream_aliquots(target_aliquots)
    end
  end

  def on_downstream_aliquots(aliquots_to_remove)
    requests_as_source.with_target.each do |request|
      request.target_asset.process_aliquots(aliquots_to_remove)
    end
  end

  def process_aliquots(aliquots_to_remove)
    new_aliquots = remove_matching_aliquots(aliquots_to_remove)
    on_downstream_aliquots(new_aliquots)
  end

  def remove_matching_aliquots(aliquots_to_remove)
    aliquots_to_remove.map do |aliquot_to_remove|
      to_remove = aliquots.select do |aliquot|
        aliquot.matches?(aliquot_to_remove)
      end

      case
      when to_remove.count > 1 then raise "Duplicate aliquots detected in asset #{display_name}."
      when to_remove.count == 1
        removed_aliquot = AliquotRecord.new(to_remove.first)
        to_remove.first.destroy
        removed_aliquot
      else # We have noting to remove
        nil
      end
    end.compact
  end
end
