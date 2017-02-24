# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

class BarcodePrinter < ActiveRecord::Base
  include Uuid::Uuidable

  belongs_to :barcode_printer_type
  validates_presence_of :barcode_printer_type
  scope :include_barcode_printer_type, -> { includes(:barcode_printer_type) }
  scope :alphabetical, -> { order(:name) }

  after_create :register_printer_in_pmb, if: :register_printers_automatically

  # for labels printing, if printer is not registered in ss
  BarcodePrinterException = Class.new(ActiveRecord::RecordNotFound)

  delegate :printer_type_id, to: :barcode_printer_type

  def plate384_printer?
    barcode_printer_type.name == '384 Well Plate'
  end

  def register_printer_in_pmb
    LabelPrinter::PmbClient.register_printer(name)
  end

  delegate :register_printers_automatically, to: :configatron

  def service_url
    configatron.barcode_service_url
  end

  def service
    @service ||= self.class.service
  end

  def self.verify(number)
    service.verify(number)
  end
end
