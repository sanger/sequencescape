# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

class Purpose < ApplicationRecord
  include Relationship::Associations
  include Uuid::Uuidable

  self.table_name = ('plate_purposes')

  class_attribute :default_prefix

  # There's a barcode printer type that has to be used to print the labels for this type of plate.
  belongs_to :barcode_printer_type
  belongs_to :source_purpose, class_name: 'Purpose'
  belongs_to :barcode_prefix, required: true
  # Things that are created are often in a default location!
  has_many :messenger_creators, inverse_of: :purpose

  before_validation :set_default_barcode_prefix

  validates :name, format: { with: /\A\w[\s\w\.\-]+\w\z/i }, presence: true, uniqueness: true
  validates :barcode_for_tecan, inclusion: { in: ['ean13_barcode', 'fluidigm_barcode'] }

  # Note: We should validate against valid asset subclasses, but running into some issues with
  # subclass loading while seeding.
  validates :target_type, presence: true

  delegate :prefix, to: :barcode_prefix, allow_nil: true

  scope :where_is_a?, ->(clazz) { where(type: [clazz, *clazz.descendants].map(&:name)) }

  def source_plate(asset)
    source_purpose_id.present? ? asset.ancestor_of_purpose(source_purpose_id) : asset.stock_plate
  end

  def barcode_type
    barcode_printer_type&.printer_type_id
  end

  def target_class
    target_type.constantize
  end

  def prefix=(prefix)
    self.barcode_prefix = BarcodePrefix.find_or_create_by(prefix: prefix)
  end

  def set_default_barcode_prefix
    self.prefix ||= default_prefix
  end
end

require_dependency 'tube/purpose'
