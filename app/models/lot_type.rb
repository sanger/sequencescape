# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2014,2015 Genome Research Ltd.

##
# A lot type governs the behaviour of a lot

class LotType < ActiveRecord::Base
  include Uuid::Uuidable

  has_many :lots, inverse_of: :lot_type
  belongs_to :target_purpose, class_name: 'Purpose'

  validates :name, :template_class, presence: true
  validates_uniqueness_of :name

  def valid_template_class
    template_class.constantize
  end

  delegate :create!, to: :lots

  def printer_type
    target_purpose.barcode_printer_type.name
  end
end
