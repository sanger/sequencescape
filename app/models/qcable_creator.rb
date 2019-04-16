class QcableCreator < ApplicationRecord
  include Uuid::Uuidable

  belongs_to :user
  belongs_to :lot
  has_many :qcables

  validates :user, presence: true
  validates :lot, presence: true

  attr_accessor :count, :barcodes

  after_create :make_qcables!

  def make_qcables!
    if count.present?
      lot.qcables.build([{ qcable_creator: self }] * count).tap do |_|
        lot.save!
      end
    end
    
    if barcodes.present?
      barcodes.split(',').collect do |barcode|
        lot.qcables.create!(qcable_creator: self, barcode: barcode)
      end
    end
  end
end
