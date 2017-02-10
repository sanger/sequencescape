# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.

class TubeCreation < AssetCreation
  class ChildTube < ActiveRecord::Base
    self.table_name = ('tube_creation_children')
    belongs_to :tube_creation
    belongs_to :tube
  end

  belongs_to :parent, class_name: 'Plate'
  include_plate_named_scope :parent

  has_many :child_tubes, class_name: 'TubeCreation::ChildTube'
  has_many :children, through: :child_tubes, source: :tube

  validates_each(:parent, unless: :no_pooling_expected?, allow_blank: true) do |record, _attr, _value|
    record.errors.add(:parent, 'has no pooling information') if record.parent.pools.empty?
  end

  def no_pooling_expected?
    parent_nil?
  end
  private :no_pooling_expected?

  def target_for_ownership
    children
  end
  private :target_for_ownership

  def create_children!
    self.children = (1..parent.pools.size).map { |_| child_purpose.create! }
  end
  private :create_children!

  def create_ancestor_plate!
    children.each do |child|
      create_ancestor_asset!(parent.plate, child) if can_create_ancestor_plate?(parent.plate, child)
    end
  end
  before_save :create_ancestor_plate!

  def record_creation_of_children
    #    children.each { |child| parent.events.create_tube!(child_purpose, child, user) }
  end
  private :record_creation_of_children
end
