
# A template is effectively a partially constructed Transfer instance, containing only the
# transfers that should be made and the final Transfer class that should be constructed.
#
# For pulldown there are at least a couple of these templates:
# - several plate-to-plate transfers of various columns (but all rows)
# - one whole plate to tube transfer
class TransferTemplate < ApplicationRecord
  include Uuid::Uuidable

  # A name is a useful way to identify templates!
  validates_presence_of :name
  validates_uniqueness_of :name

  # A template creates a particular Transfer subclass.
  validates_presence_of :transfer_class_name

  # A set of transfers that should be made.
  serialize :transfers

  def transfer_class
    @transfer_class ||= transfer_class_name.constantize
  end

  def create!
    transfer_class.create!(transfer_attributes)
  end

  def preview!
    transfer_class.preview!(transfer_attributes)
  end

  private

  def transfer_attributes
    attributes[:transfers] = transfers if transfers.present?
    attributes
  end
end
