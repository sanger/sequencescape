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

    def transfer_request_class_from(parent_purpose)
      relationship = parent_relationships.find_by(parent_id: parent_purpose.id)
      return parent_purpose.default_transfer_class if relationship.nil?
      relationship.transfer_request_class
    end

    deprecate def default_transfer
      stock_plate? ? RequestType.initial_transfer : RequestType.transfer
    end

    def default_transfer_class_name
      stock_plate? ? :initial : :standard
    end

    def default_transfer_class
      TransferRequest.subclass(default_transfer_class_name)
    end
  end

  self.table_name = ('plate_purpose_relationships')
  belongs_to :parent, class_name: 'Purpose'
  belongs_to :child, class_name: 'Purpose'

  enum transfer_request_class_name: %i[standard initial initial_downstream cherrypick pacbio_initial]

  scope :with_parent, ->(plate_purpose) { where(parent_id: plate_purpose) }
  scope :with_child,  ->(plate_purpose) { where(child_id: plate_purpose) }

  def transfer_request_class
    TransferRequest.subclass(transfer_request_class_name)
  end

  private

  def set_default_transfer_request
    self.transfer_request_class_name ||= parent.default_transfer_class_name
  end
end
