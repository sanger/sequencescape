# Represents a barcode printer, where {#name} is the hostname of the printer
# eg. d304bc
# BarcodePrinterType records which label type (eg. tube or plate labels) is loaded
# in the printer, and ensures that we can:
#  - Correctly filter the list of printers displayed to be suitable for the asset
#  - Send an appropriate label template to the printer
class BarcodePrinter < ApplicationRecord
  include Uuid::Uuidable

  # @!attribute name
  #   @return [String] The hostname of the printer, eg. d304bc

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
    # configatron.barcode_service_url
    'DEPRECATED'
  end

  def service
    @service ||= self.class.service
  end

  def self.verify(number)
    service.verify(number)
  end
end
