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

  def print(labels, printer, barcode_prefix=nil, barcode_type= "short",study_name=nil, user_login=nil)
    initialize
    printables = []
    count = 0

    labels.each do |label|
      number = label.number
      if label.study
        name = label.study.gsub("_", " ").gsub("-"," ")
      end
      if label.prefix
        prefix = label.prefix
        barcode_prefix = label.prefix
      else
        prefix = label.study[0..1]
      end
      
      output_plate_purpose = label.output_plate_purpose
      barcode_desc = "#{name}_#{number}"

      if prefix =="LE"
        label.study = label.study[2..label.study.length]
      else
        prefix = barcode_prefix
      end
      barcode_text = "#{prefix} #{number.to_s}"

      if barcode_type == "long"
        if study_name
          barcode_text = "#{study_name}"
        end
        if user_login
          barcode_desc = "#{user_login} #{output_plate_purpose} #{name}"
        end
      end

      printables[count] = BarcodeLabelDTO.new(number.to_i, barcode_desc, barcode_text, "#{prefix}", barcode_desc, label.suffix)
      count += 1
    end

    begin
      barcode_printer = BarcodePrinter.find_by_name(printer) or raise ActiveRecord::RecordNotFound, "Could not find barcode printer #{printer.inspect}"
      result = service.printLabels(printer, barcode_printer.barcode_printer_type.printer_type_id, 1, 1, printables)
    rescue SOAP::HTTPStreamError
      raise BarcodeException, "problem connecting to Barcode service", caller
    end

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
