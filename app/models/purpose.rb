# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2015 Genome Research Ltd.

class Purpose < ActiveRecord::Base
  self.table_name = ('plate_purposes')

  include Relationship::Associations
  include Uuid::Uuidable

  def source_plate(asset)
    source_purpose_id.present? ? asset.ancestor_of_purpose(source_purpose_id) : asset.stock_plate
  end

  # There's a barcode printer type that has to be used to print the labels for this type of plate.
  belongs_to :barcode_printer_type
  belongs_to :source_purpose, class_name: 'Purpose'

  def barcode_type
    barcode_printer_type.printer_type_id
  end

  # Things that are created are often in a default location!
  belongs_to :default_location, class_name: 'Location'
  has_many :messenger_creators, inverse_of: :purpose

  validates :name, format: { with: /\A\w[\s\w\.\-]+\w\z/i }, presence: true, uniqueness: true
  validates :barcode_for_tecan, inclusion: { in: ['ean13_barcode', 'fluidigm_barcode'] }

  # Note: We should validate against valid asset subclasses, but running into some issues with
  # subclass loading while seeding.
  validates :target_type, presence: true

 scope :where_is_a?, ->(clazz) { where(type: [clazz, *clazz.descendants].map(&:name)) }

  def target_class
    target_type.constantize
  end
end

require_dependency 'tube/purpose'
