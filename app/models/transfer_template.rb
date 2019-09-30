# A template is effectively a partially constructed Transfer instance, containing only the
# transfers that should be made and the final Transfer class that should be constructed.
#
# For pulldown there are at least a couple of these templates:
# - several plate-to-plate transfers of various columns (but all rows)
# - one whole plate to tube transfer
class TransferTemplate < ApplicationRecord
  include Uuid::Uuidable

  # A name is a useful way to identify templates!
  validates :name, presence: true, uniqueness: { case_sensitive: false }

  # A template creates a particular Transfer subclass.
  validates :transfer_class_name, presence: true

  # A set of transfers that should be made.
  serialize :transfers

  def transfer_class
    @transfer_class ||= transfer_class_name.constantize
  end

  def create!(attributes)
    transfer_class.create!(transfer_attributes(attributes))
  end

  def preview!(attributes)
    transfer_class.preview!(transfer_attributes(attributes))
  end

  private

  def transfer_attributes(attributes)
    attributes[:transfers] = transfers if transfers.present?
    attributes
  end
end
