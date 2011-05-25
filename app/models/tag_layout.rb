# Lays out the tags in the specified tag group in a particular pattern.
#
# In pulldown they use only one set of tags and put them into wells in a particular pattern: by columns, or
# by rows.  Depending on the size of the tag group that is used by the layout template it either repeats (for
# example, 8 tags in the group laid out in columns would repeat the tags across the plate), or it
# doesn't (for example, a 96 tag group would occupy an entire 96 well plate).
class TagLayout < ActiveRecord::Base
  # The user performing the layout
  belongs_to :user

  # The tag group to layout on the plate
  belongs_to :tag_group
  validates_presence_of :tag_group

  # The plate we'll be laying out the tags into
  belongs_to :plate
  validates_presence_of :plate

  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tags_into_wells

  # Subclasses override this method to provide the implementation of the tag layout
  def layout_tags_into_wells
    raise StandardError, 'Specific implementation required'
  end
  private :layout_tags_into_wells

  # Convenience mechanism for laying out tags in a particular fashion.
  def layout_tags_into_wells_by(order)
    wells_on_plate = Hash[plate.wells.map { |well| [ well.map, well ] }]
    tags           = tag_group.tags.sort_by(&:map_id)
    Map.send(:"walk_plate_in_#{order}", plate.size) do |map, index|
      AssetLink.connect(tags[index % tags.length].create!, wells_on_plate[map])
    end
  end
  private :layout_tags_into_wells_by
end
