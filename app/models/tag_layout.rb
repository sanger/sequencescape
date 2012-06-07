# Lays out the tags in the specified tag group in a particular pattern.
#
# In pulldown they use only one set of tags and put them into wells in a particular pattern: by columns, or
# by rows.  Depending on the size of the tag group that is used by the layout template it either repeats (for
# example, 8 tags in the group laid out in columns would repeat the tags across the plate), or it
# doesn't (for example, a 96 tag group would occupy an entire 96 well plate).
class TagLayout < ActiveRecord::Base
  include Uuid::Uuidable
  include ModelExtensions::TagLayout

  self.inheritance_column = "sti_type"

  # The user performing the layout
  belongs_to :user
  validates_presence_of :user

  # The tag group to layout on the plate, along with the substitutions that should be made
  belongs_to :tag_group
  validates_presence_of :tag_group
  serialize :substitutions

  before_validation do |record|
    record.substitutions ||= {}
  end

  # The plate we'll be laying out the tags into
  belongs_to :plate
  validates_presence_of :plate

  include Asset::Ownership::ChangesOwner
  set_target_for_owner(:plate)

  # After loading the record from the database, inject the behaviour.
  def after_initialize
    extend(direction_algorithm.constantize) unless direction_algorithm.blank?
    extend(walking_algorithm.constantize)   unless walking_algorithm.blank?
  end

  def wells_in_walking_order
    plate.wells.send(:"in_#{direction.gsub(' ', '_')}_major_order")
  end
  private :wells_in_walking_order

  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tags_into_wells

  # Convenience mechanism for laying out tags in a particular fashion.
  def layout_tags_into_wells
    # Make sure that the substitutions requested by the user are handled before applying the tags
    # to the wells.
    tag_map_id_to_tag = ActiveSupport::OrderedHash[tag_group.tags.sort_by(&:map_id).map { |tag| [tag.map_id.to_s, tag] }]
    tags              = tag_map_id_to_tag.map { |k,tag| substitutions.key?(k) ? tag_map_id_to_tag[substitutions[k]] : tag }
    walk_wells do |well, index|
      tags[index % tags.length].tag!(well) unless well.aliquots.empty?
    end

    # We can now check that the pools do not contain duplicate tags.
    pool_to_tag = Hash.new { |h,k| h[k] = [] }
    plate.wells.walk_in_pools do |pool_id, wells|
      pool_to_tag[pool_id] = wells.map { |well| well.aliquots.map(&:tag).uniq }.flatten
    end
    errors.add_to_base('duplicate tags within a pool') if pool_to_tag.any? { |_,t| t.uniq.size > 1 }
  end
  private :layout_tags_into_wells

end
