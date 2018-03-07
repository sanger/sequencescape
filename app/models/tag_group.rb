# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2018 Genome Research Ltd.

class TagGroup < ApplicationRecord
  include Uuid::Uuidable
  attr_accessor :oligos_text

  has_many :tags, ->() { order('map_id ASC') }

  scope :include_tags, ->() { includes(:tags) }

  scope :visible, -> { where(visible: true) }

  before_validation :check_entered_oligos, on: %i[create build]
  validates_presence_of :name
  validates_uniqueness_of :name
  # validates_presence_of :oligos_text
  validate :format_of_oligos, on: %i[create build]
  validate :any_valid_oligos, on: %i[create build]

  def tags_sorted_by_map_id
    tags.sort_by(&:map_id)
  end

  # Returns a Hash that maps from the tag index in the group to the oligo sequence for the tag
  def indexed_tags
    Hash[tags.map { |tag| [tag.map_id, tag.oligo] }]
  end

  def format_of_oligos
    p 'checking format_of_oligos'
    errors.add(:base, I18n.t('tag_groups.errors.invalid_oligos_found') + @invalid_oligos_list.join(',')) unless @invalid_oligos_list.size.zero?
  end

  def any_valid_oligos
    p 'checking any_valid_oligos'
    errors.add(:base, I18n.t('tag_groups.errors.no_valid_oligos_found')) unless @valid_oligos_count > 0
  end

  def check_entered_oligos
    oligos_list = oligos_text&.split(/\s+/) || []
    p "#{oligos_list}"
    @invalid_oligos_list = []
    @valid_oligos_count = 0
    oligos_list.each do |cur_oligo|
      p "cur_oligo = #{cur_oligo}"
      if cur_oligo.match?(/^[ACGTacgt]*$/)
        p 'valid'
        @valid_oligos_count =+ 1
      else
        p 'invalid'
        @invalid_oligos_list << cur_oligo
      end
    end
  end
end
