require 'print_barcode'
class BarcodePrinter < ActiveRecord::Base
  belongs_to :barcode_printer_type
  validates_presence_of :barcode_printer_type


  URL = configatron.barcode_service_url

  def service
    @service ||= self.class.service
  end

  def printer_type_id
    self.barcode_printer_type.printer_type_id
  end

  def print_labels(labels, barcode_prefix=nil, barcode_type= "short",study_name=nil, user_login=nil)
    service.print_labels(labels, name, printer_type_id,
                         :prefix => barcode_prefix,
                         :type => barcode_type, 
                         :study_name => study_name,
                         :user_login => user_login)
  end
  def self.print(labels, printer, *args)
      printer = BarcodePrinter.find_by_name(printer) or raise ActiveRecord::RecordNotFound, "Could not find barcode printer #{printer.inspect}"

      printer.print_labels(labels, *args)

  end

  def self.verify(number)
    serive.verify(number)
  end

  @@service = nil
  class << self
    def service
      return @@service unless @@service.nil?
      return PrintBarcode::Service.new(configatron.barcode_service_url)
    end
    alias_method(:init_service, :service)
  end
end
