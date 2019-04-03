# Legacy class which used to represent potential products before they had actually
# been created.
# @deprecate JG: As far as I am aware while these are still being generated in a few places
#            they are no longer required and can probably be removed.
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

  validates_presence_of :version
  validates_presence_of :name
  validates_uniqueness_of :name, scope: [:version], on: :create, message: 'already in use (item)'

  scope :for_search_query, ->(query) {
                             where(['name LIKE ? OR id=?', "%#{query}%", query])
                           }

  before_validation :set_version, on: :create

  def set_version
    things_with_same_name = self.class.where(name: name)
    if things_with_same_name.empty?
      increment(:version)
    else
      self.version = things_with_same_name.size + 1
    end
  end
end
