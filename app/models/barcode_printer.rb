class BarcodePrinter < ActiveRecord::Base
  belongs_to :barcode_printer_type
  validates_presence_of :barcode_printer_type

  require 'soap/wsdlDriver'
  require 'barcode_wsdl'
  require 'exception/barcode_exception'

  URL = configatron.barcode_service_url

  def service
    @service ||= self.class.service
  end

  def generate_printable(label, options={})
    barcode_prefix = options[:barcode_prefix]
    barcode_type   = options[:barcode_type] || "short" 
    study_name     = options[:study_name]
    user_login    = options[:user_login]

    output_plate_purpose = label.output_plate_purpose

    barcode_desc = label.barcode_description
    barcode_text = label.barcode_text(barcode_prefix)
    if barcode_type == "long"
      barcode_text = "#{study_name}" if study_name
      barcode_desc = "#{user_login} #{output_plate_purpose} #{label.barcode_name}" if user_login
    end

    printable = BarcodeLabelDTO.new(label.number.to_i, barcode_desc, barcode_text, label.barcode_prefix(barcode_prefix), barcode_desc, label.suffix)
  end


  def printer_type_id
    self.barcode_printer_type.printer_type_id
  end

  def print(printables)
    begin
      result = service.printLabels(self.name, self.printer_type_id, 1, 1, printables)
    rescue SOAP::HTTPStreamError
      raise BarcodeException, "problem connecting to Barcode service", caller
    end
  end

  def print_labels(labels, barcode_prefix=nil, barcode_type= "short",study_name=nil, user_login=nil)
    printables = labels.map do |l|
      generate_printable(l, :barcode_prefix => barcode_prefix,
                         :barcode_type => barcode_type,
                         :study_name => study_name,
                         :user_login => user_login)
    end
    print(printables)
  end
  def self.print(labels, printer, *args)
      printer = BarcodePrinter.find_by_name(printer) or raise ActiveRecord::RecordNotFound, "Could not find barcode printer #{printer.inspect}"

      printer.print_labels(labels, *args)

  end

  def self.verify(number)
    response = service.verifyNumber(number.to_s)
    success = false
    if response.process == 'Good'
      success = true
    end
    success
  end

  @@service = nil
  class << self
    def service
      return @@service unless @@service.nil?
      return SOAP::WSDLDriverFactory.new(configatron.barcode_service_url).create_rpc_driver
    end
    alias_method(:init_service, :service)
  end
end
