# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2011,2012,2014,2015 Genome Research Ltd.

# Lays out the tags in the specified tag group in a particular pattern.
#
# In pulldown they use only one set of tags and put them into wells in a particular pattern: by columns, or
# by rows.  Depending on the size of the tag group that is used by the layout template it either repeats (for
# example, 8 tags in the group laid out in columns would repeat the tags across the plate), or it
# doesn't (for example, a 96 tag group would occupy an entire 96 well plate).
class TagLayout < ApplicationRecord
  include Uuid::Uuidable
  include ModelExtensions::TagLayout
  include Asset::Ownership::ChangesOwner

  attr_accessor :tags_per_well

  UnknownDirection = Struct.new(:direction)
  UnknownWalking = Struct.new(:walking_by)

  DIRECTIONS = {
    'column'          => 'TagLayout::InColumns',
    'row'             => 'TagLayout::InRows',
    'inverse column'  => 'TagLayout::InInverseColumns',
    'inverse row'     => 'TagLayout::InInverseRows',
    'column then row' => 'TagLayout::InColumnsThenRows'
  }.freeze

  WALKING_ALGORITHMS = {
    'wells in pools'     => 'TagLayout::WalkWellsByPools',
    'wells of plate'     => 'TagLayout::WalkWellsOfPlate',
    'manual by pool'     => 'TagLayout::WalkManualWellsByPools',
    'as group by plate'  => 'TagLayout::AsGroupByPlate',
    'manual by plate'    => 'TagLayout::WalkManualWellsOfPlate',
    'quadrants'          => 'TagLayout::Quadrants'
  }.freeze

  self.inheritance_column = 'sti_type'

  serialize :substitutions, Hash

  # The user performing the layout
  belongs_to :user, required: true
  # The tag group to layout on the plate, along with the substitutions that should be made
  belongs_to :tag_group, required: true
  belongs_to :tag2_group, class_name: 'TagGroup'
  # The plate we'll be laying out the tags into
  belongs_to :plate, required: true

  validates :direction, inclusion: { in: DIRECTIONS.keys }
  validates :walking_by, inclusion: { in: WALKING_ALGORITHMS.keys }

  validates_presence_of :direction_algorithm
  validates_presence_of :walking_algorithm

  # After creating the instance we can layout the tags into the wells.
  after_create :layout_tags_into_wells, if: :valid?

  set_target_for_owner(:plate)

  delegate :direction, to: :direction_algorithm_module
  delegate :walking_by, :walk_wells, :apply_tags, to: :walking_algorithm_helper

  def direction=(new_direction)
    self.direction_algorithm = DIRECTIONS.fetch(new_direction) { UnknownDirection.new(new_direction) }
  end

  def walking_by=(walk)
    self.walking_algorithm = WALKING_ALGORITHMS.fetch(walk) { UnknownWalking.new(walk) }
  end

  def wells_in_walking_order
    @wiwo ||= plate.wells
                   .send(direction_algorithm_module.well_order_scope)
                   .includes(aliquots: [:tag, :tag2])
  end

  def direction_algorithm_module
    direction_algorithm.constantize
  end

  private

  def walking_algorithm_class
    walking_algorithm.constantize
  end

  def walking_algorithm_helper
    @walking_algorithm_helper ||= walking_algorithm_class.new(self)
  end

  # Convenience mechanism for laying out tags in a particular fashion.
  def layout_tags_into_wells
    # Make sure that the substitutions requested by the user are handled before applying the tags
    # to the wells.
    walk_wells do |well, index, index2 = index|
      tag_index = (index + initial_tag) % tags.length
      tag2_index = (index2 + initial_tag) % tag2s.length if tag2?
      apply_tags(well, tags[tag_index], tag2s[tag2_index || 0])
      well.set_as_library
    end
  end

  #
  # Returns an array of tags in map order, but with any substitutions applied.
  #
  #
  # @return [Array<Tag>] An ordered array of tags
  #
  def tags
    @tags ||= ordered_tags_for(tag_group)
  end

  def tag2s
    @tag2s ||= tag2? ? ordered_tags_for(tag2_group) : []
  end

  def ordered_tags_for(tag_group)
    tag_hash = build_tag_hash(tag_group)
    tag_hash.map do |map_id, tag|
      substitutions.key?(map_id) ? tag_hash[substitutions[map_id]] : tag
    end
  end

  def build_tag_hash(tag_group)
    tag_group.tags.order(map_id: :asc).index_by { |tag| tag.map_id.to_s }
  end

  def tag2?
    tag2_group.present?
  end
end
