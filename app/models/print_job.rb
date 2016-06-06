#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2015,2016 Genome Research Ltd.
require 'lib/pmb_client'

class PrintJob

	attr_reader :barcode_printer, :label, :options, :label_template_id

	def initialize(barcode_printer, label, options)
		@barcode_printer = barcode_printer
		@label = label
		@options = options
		# @label_template_id = barcode_printer.label_template
		@label_template_id = 6
	end

	def execute
		attributes = build_attributes
		PmbClient::PrintMyBarcode.print(attributes)
	end

	def build_attributes
		printer.merge(label_template).merge(labels)
	end

	def labels
		label.new(options).to_h
	end

	def printer
		{printer_name: barcode_printer.name}
	end

	def label_template
		{label_template_id: label_template_id}
	end

end