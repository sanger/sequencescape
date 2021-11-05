# frozen_string_literal: true

# Assigns multiple tags to each well sequentially.
class TagLayout::AsFixedGroupByPlate < TagLayout::Walker
  DEFAULT_TAGS_PER_WELL = 4

  self.walking_by = 'as fixed group by plate'

  def tags_per_well
    tag_layout.tags_per_well || DEFAULT_TAGS_PER_WELL
  end

  def walk_wells
    wells_in_walking_order.each_with_index do |well, well_index|
      tags_per_well.times do |tag_index|
        index = (well_index * tags_per_well) + tag_index
        yield(well, index) unless well.nil?
      end
    end
  end

  # Over-ridden in the as group by plate fixed module to allow the application of multiple tags.
  # We don't support dual indexing here currently.
  def apply_tags(well, tag, tag2)
    raise StandardError, 'Dual indexing is not supported by this template' if tag2.present?

    tag.multitag!(well) unless well.aliquots.empty?
  end
end
