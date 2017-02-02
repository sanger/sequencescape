# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2015 Genome Research Ltd.
class Equipment < ActiveRecord::Base
  validates_presence_of :name, :equipment_type
  before_validation :set_defaults
  after_create :update_barcode

  def set_defaults
    self.prefix ||= 'XX'
  end

  def update_barcode
    self.ean13_barcode ||= Barcode.calculate_barcode(prefix, id)
    save!
  end

  def barcode_number
     Barcode.number_to_human(self.ean13_barcode)
  end

  def suffix
    Barcode.calculate_checksum(prefix, barcode_number)
  end
end
