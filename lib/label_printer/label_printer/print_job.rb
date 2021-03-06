# require 'pmb_client'

module LabelPrinter
  class PrintJob # rubocop:todo Style/Documentation
    include ActiveModel::Validations

    attr_reader :printer_name, :label_class, :options, :labels

    def initialize(printer_name, label_class, options)
      @printer_name = printer_name
      @label_class = label_class
      @options = options
    end

    def execute # rubocop:todo Metrics/MethodLength
      begin
        attributes = build_attributes
        LabelPrinter::PmbClient.print(attributes)
      rescue LabelPrinter::PmbException => e
        errors.add(:printmybarcode, e)
        return false
      rescue BarcodePrinter::BarcodePrinterException => e
        errors.add(:printer, e)
        return false
      rescue SampleManifest::MultiplexedLibraryBehaviour::Core::MxLibraryTubeException => e
        errors.add(:mx_tube, e)
        return false
      end

      true
    end

    def build_attributes
      printer_name_attribute.merge(label_template_id_attribute).merge(labels_attribute)
    end

    def labels_attribute
      printer = find_printer
      printer_type_class = { printer_type_class: printer.barcode_printer_type.class }
      @labels = label_class.new(options.merge(printer_type_class)).to_h
    end

    def printer_name_attribute
      { printer_name: printer_name }
    end

    def label_template_id_attribute
      { label_template_id: label_template_id }
    end

    def label_template_id
      printer = find_printer
      name = printer.barcode_printer_type.label_template_name
      LabelPrinter::PmbClient.get_label_template_by_name(name).fetch('data').first['id']
    end

    def find_printer
      BarcodePrinter.find_by(name: printer_name) or
        raise BarcodePrinter::BarcodePrinterException.new, "Could not find barcode printer #{printer_name.inspect}"
    end

    def success
      "Your #{number_of_labels} label(s) have been sent to printer #{printer_name}"
    end

    def number_of_labels
      labels[:labels][:body] ? labels[:labels][:body].count : 0
    end
  end
end
