# frozen_string_literal: true
# require 'pmb_client'

module LabelPrinter
  class PrintJob
    include ActiveModel::Validations

    attr_reader :printer_name, :label_class, :options, :labels

    def initialize(printer_name, label_class, options)
      @printer_name = printer_name
      @label_class = label_class
      @options = options
    end

    def execute # rubocop:todo Metrics/MethodLength
      begin
        LabelPrinter::PmbClient.print(build_attributes)
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
      @build_attributes ||=
        { printer_name:, label_template_name:, labels: labels_attribute }
    end

    # returns: a list of labels
    def labels_attribute
      printer = find_printer
      printer_type_class = { printer_type_class: printer.barcode_printer_type.class }
      @labels = label_class.new(options.merge(printer_type_class)).labels
    end

    # Returns the name of the label template to use for this print job.
    # If not specified in the options during initialisation, the label template
    # name configured for the printer in the database is used.
    #
    # @return [String] the name of the label template to use for this print job
    #
    def label_template_name
      return options[:label_template_name] if options[:label_template_name]

      printer = find_printer
      printer.barcode_printer_type.label_template_name
    end

    def find_printer
      BarcodePrinter.find_by(name: printer_name) or
        raise BarcodePrinter::BarcodePrinterException.new, "Could not find barcode printer #{printer_name.inspect}"
    end

    def success
      "Your #{number_of_labels} label(s) have been sent to printer #{printer_name}"
    end

    def number_of_labels
      labels.count
    end
  end
end
