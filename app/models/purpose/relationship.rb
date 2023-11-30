# frozen_string_literal: true

#
# Keeps track of plate parent-child relationships
# Mostly unused now, but still the authoritative source of relationships
# in Generic Lims. Once Generic Lims is retires we can loose all this
#
# @author [jg16]
#
class Purpose::Relationship < ApplicationRecord
  module Associations
    def self.included(base)
      base.class_eval do
        has_many :child_relationships, class_name: 'Purpose::Relationship', foreign_key: :parent_id, dependent: :destroy
        has_many :child_purposes, through: :child_relationships, source: :child

        has_many :parent_relationships, class_name: 'Purpose::Relationship', foreign_key: :child_id, dependent: :destroy
        has_many :parent_purposes, through: :parent_relationships, source: :parent
      end
    end
  end

  self.table_name = ('plate_purpose_relationships')
  belongs_to :parent, class_name: 'Purpose'
  belongs_to :child, class_name: 'Purpose'

  scope :with_parent, ->(plate_purpose) { where(parent_id: plate_purpose) }
  scope :with_child, ->(plate_purpose) { where(child_id: plate_purpose) }
end
