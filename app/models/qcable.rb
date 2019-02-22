##
# A Qcable is an element of a lot which must be approved
# before it may be used.

# require 'qcable/state_machine'

require 'aasm'

class Qcable < ApplicationRecord
  include Uuid::Uuidable
  include AASM
  include Qcable::Statemachine

  belongs_to :lot, inverse_of: :qcables
  belongs_to :asset
  belongs_to :qcable_creator, inverse_of: :qcables

  has_one :stamp_qcable, inverse_of: :qcable, class_name: 'Stamp::StampQcable'
  has_one :stamp, through: :stamp_qcable

  validates :lot, :asset, :state, :qcable_creator, presence: true

  before_validation :create_asset!, on: :create

  delegate :bed, :order, to: :stamp_qcable, allow_nil: true
  delegate :ean13_barcode, :machine_barcode, :human_barcode, to: :primary_barcode, allow_nil: true

  scope :include_for_json, -> { includes([:asset, :lot, :stamp, :stamp_qcable]) }

  scope :stamped, -> { includes([:stamp_qcable, :stamp]).where('stamp_qcables.id IS NOT NULL').order('stamps.created_at ASC, stamp_qcables.order ASC') }

  has_many :barcodes, through: :asset
  # We accept not only an individual barcode but also an array of them.  This builds an appropriate
  # set of conditions that can find any one of these barcodes.  We map each of the individual barcodes
  # to their appropriate query conditions (as though they operated on their own) and then we join
  # them together with 'OR' to get the overall conditions.
  scope :with_barcode, ->(*barcodes) {
    db_barcodes = barcodes.flatten.each_with_object([]) do |source_bc, store|
      next if source_bc.blank?

      store.concat(Barcode.extract_barcode(source_bc))
    end
    joins(:barcodes).where(barcodes: { barcode: db_barcodes }).distinct
  }

  def stamp_index
    return nil if stamp_qcable.nil?

    lot.qcables.stamped.index(self)
  end

  private

  def asset_purpose
    lot.target_purpose
  end

  def create_asset!
    return true if lot.nil?

    self.asset ||= asset_purpose.create!
  end

  def primary_barcode
    barcodes.first
  end
end
