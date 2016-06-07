require 'test_helper'

class PrintJobTest < ActiveSupport::TestCase

	context "Print job for plates creation" do

		attr_reader :print_job, :plates, :plate, :plate_purpose, :barcode_printer, :attributes

		setup do
			@barcode_printer = BarcodePrinter.new(name: 'test')
			@plates = [(create :child_plate)]
			@plate = plates[0]
			@plate_purpose = plate.plate_purpose
			@attributes = {printer_name: barcode_printer.name,
							label_template_id: 6,
							labels: {body:
								[{main_label:
									{top_left: "#{Date.today}",
									bottom_left: "#{plate.sanger_human_barcode}",
									top_right: "#{plate_purpose.name.to_s}",
									bottom_right: "user #{plate.find_study_abbreviation_from_parent}",
									top_far_right: "#{plate.parent.try(:barcode)}",
									barcode: "#{plate.ean13_barcode}"}}]
								}
							}
			@print_job = PrintJob.new(barcode_printer, Label::PlateLabel, plates: plates, plate_purpose: plate_purpose, user_login: 'user')
		end

		should "have attributes" do
			assert print_job.barcode_printer
			assert print_job.label_template_id
			assert print_job.label
		end

		should "build attributes" do
			assert_equal attributes, print_job.build_attributes
		end

		should "print contact pmb to print labels" do
			PmbClient::PrintMyBarcode.expects(:print).with(attributes).returns('success')
			assert_equal 'success', print_job.execute
		end

	end

end