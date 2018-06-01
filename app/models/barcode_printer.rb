
class BarcodePrinter < ApplicationRecord
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
