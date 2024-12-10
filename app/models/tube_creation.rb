# frozen_string_literal: true
# Create one tube per pool for the provided parent
class TubeCreation < AssetCreation
  class ChildTube < ApplicationRecord
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

  private

  def no_pooling_expected?
    parent_nil?
  end

  def target_for_ownership
    children
  end

  def create_children!
    self.children = Array.new(parent.pools.size) { child_purpose.create! }
  end
end
