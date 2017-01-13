class Purpose::Relationship < ActiveRecord::Base
  module Associations
    def self.included(base)
      base.class_eval do
        has_many :child_relationships, class_name: 'Purpose::Relationship', foreign_key: :parent_id, dependent: :destroy
        has_many :child_purposes, through: :child_relationships, source: :child

        has_many :parent_relationships, class_name: 'Purpose::Relationship', foreign_key: :child_id, dependent: :destroy
        has_many :parent_purposes, through: :parent_relationships, source: :parent
      end
    end

    # Returns the transfer request type to use between this purpose and the parent given
    # If no relationship exists, use the default transfer
    def transfer_request_type_from(parent_purpose)
      relationship = parent_relationships.find_by(parent_id: parent_purpose.id)
      return parent_purpose.default_transfer if relationship.nil?
      relationship.transfer_request_type
    end

    def default_transfer
      stock_plate? ? RequestType.initial_transfer : RequestType.transfer
    end
  end

  self.table_name = ('plate_purpose_relationships')
  belongs_to :parent, class_name: 'Purpose'
  belongs_to :child, class_name: 'Purpose'

  belongs_to :transfer_request_type, class_name: 'RequestType'

  before_validation :set_default_transfer_request

  scope :with_parent, ->(plate_purpose) { where(parent_id: plate_purpose) }
  scope :with_child,  ->(plate_purpose) { where(child_id: plate_purpose) }

  private

  def set_default_transfer_request
    self.transfer_request_type ||= parent.default_transfer
  end
end
