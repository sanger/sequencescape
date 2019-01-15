# frozen_string_literal: true

#
# Provides methods mainly geared up to handle the display of tags and tag groups
#
module TagSubstitutionHelper
  # Returns a user friendly name for the corresponding tag
  def tag_name(tag_id)
    return 'Untagged' if tag_id == Aliquot::UNASSIGNED_TAG

    @complete_tags.dig(tag_id.to_i, 0)
  end

  def tag_options_for(tag_id)
    return { 'No group' => [['Untagged', Aliquot::UNASSIGNED_TAG]] } if tag_id == Aliquot::UNASSIGNED_TAG

    tags_in_groups.slice(@complete_tags.fetch(tag_id.to_i).last)
  end

  def tags_in_groups
    @tags_in_groups ||= @complete_tags.each_with_object({}) do |(_id, info), store|
      store[info.last] ||= []
      store[info.last] << info[0, 2]
    end
  end
end
