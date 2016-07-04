#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.
# require 'lib/pmb_client'

module LabelPrinter

	class PrintJob

		attr_reader :printer, :label_class, :options, :label_template_id

		def initialize(printer_name, label_class, options)
			@printer = find_printer(printer_name)
			@label_class = label_class
			@options = options
			@label_template_id = find_label_template_id
		end

		def execute
			attributes = build_attributes
			LabelPrinter::PmbClient.print(attributes)
		end

		def build_attributes
			printer_name_attribute.merge(label_template_id_attribute).merge(labels_attribute)
		end

		def labels_attribute
			label_class.new(options).to_h
		end

		def printer_name_attribute
			{printer_name: printer.name}
		end

		def label_template_id_attribute
			{label_template_id: label_template_id}
		end

		def find_label_template_id
			name = printer.barcode_printer_type.label_template_name
			LabelPrinter::PmbClient.get_label_template_by_name(name).fetch("data").first["id"]
		end

		def find_printer(printer_name)
			BarcodePrinter.find_by_name(printer_name) or raise ActiveRecord::RecordNotFound, "Could not find barcode printer '#{printer_name.inspect}'"
		end

	end
end