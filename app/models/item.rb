# frozen_string_literal: true
# Legacy class which used to represent potential products before they had actually
# been created.
# @deprecated JG: As far as I am aware while these are still being generated in a few places
#             they are no longer required and can probably be removed.
class Item < ApplicationRecord
  include Uuid::Uuidable
  include EventfulRecord
  extend EventfulRecord

  has_many_events
  has_many_lab_events

  @@cached_requests = nil

  belongs_to :submission
  belongs_to :study

  has_many :requests, dependent: :destroy
  has_many :comments, as: :commentable

  validates :version, presence: true
  validates :name, presence: true
  validates :name,
            uniqueness: {
              scope: [:version],
              on: :create,
              message: 'already in use (item)',
              case_sensitive: false
            }

  scope :for_search_query, ->(query) { where(['name LIKE ? OR id=?', "%#{query}%", query]) }

  before_validation :set_version, on: :create

  def set_version
    things_with_same_name = self.class.where(name:)
    if things_with_same_name.empty?
      increment(:version)
    else
      self.version = things_with_same_name.size + 1
    end
  end
end
