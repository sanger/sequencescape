# This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

# Assigns multiple tags to each well.

module TagLayout::AsGroupByPlate
  attr_writer :tags_per_well

  DEFAULT_TAGS_PER_WELL = 4

  def self.walking_by
    'as group by plate'
  end

  def walking_by
    TagLayout::AsGroupByPlate.walking_by
  end

  def tags_per_well
    @tags_per_well || DEFAULT_TAGS_PER_WELL
  end

  def walk_wells
    wells_in_walking_order.with_aliquots.each_with_index do |well, well_index|
      tags_per_well.times do |tag_index|
        index = well_index * tags_per_well + tag_index
        yield(well, index) unless well.nil?
      end
    end
  end
  private :walk_wells

  # Over-ridden in the as group by plate module to allow the application of multiple tags.
  def apply_tag(tag, well)
    tag.multitag!(well) unless well.aliquots.empty?
  end
  private :apply_tag
end
