# frozen_string_literal: true
class QcableCreator < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :user
  belongs_to :lot
  has_many :qcables

  validates :user, presence: true
  validates :lot, presence: true

  attr_accessor :count, :barcodes, :supplied_barcode

  after_create :make_qcables!

  def make_qcables!
    return qcables_by_supplied_barcode! if supplied_barcode.present?

    qcables_by_count! if count.present?
    qcables_by_barcode! if barcodes.present?
  end

  def qcables_by_count!
    lot.qcables.build([{ qcable_creator: self }] * count).tap { |_| lot.save! }
  end

  def qcables_by_barcode!
    barcodes.split(',').collect { |barcode| lot.qcables.create!(qcable_creator: self, barcode: barcode) }
  end

  # Creates using the supplied plate barcode we received from baracoda
  def qcables_by_supplied_barcode!
    lot.qcables.create!(qcable_creator: self, supplied_barcode: supplied_barcode)
  end
end
