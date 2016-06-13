require 'test_helper'

class SangerBarcodeTest < ActiveSupport::TestCase

	attr_reader :label

	context "printing from plate controller/ plate creator" do

		#number is plate.barcode
		#study is plate.find_study_abbreviation_from_parent
		#suffix is plate.parent.try(:barcode)
		#prefix is plate.barcode_prefix.prefix

		setup do
			@label = Sanger::Barcode::Printing::Label.new number: 9168090, study: 'Gen_Ctrl', suffix: 134443, prefix: 'DN'
		end

		should "it should have options" do
			assert_equal 9168090, label.number
			assert_equal 'Gen_Ctrl', label.study
			assert_equal 134443,  label.suffix
			assert_equal 'DN', label.prefix
		end

		should 'it should have barcode name and barcode description' do
			assert_equal 'Gen Ctrl', label.barcode_name
			assert_equal 'Gen Ctrl_9168090', label.barcode_description
		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#1 is barcode_printer.printer_type_id
			#prefix is Plate.prefix
			#study_name is plate.plate_purpose.name.to_s
			#user_login is user.login
			barcode_label_dto = label.printable(1, prefix: 'DN',
	                       type: 'long',
	                       study_name: 'Stock Plate',
	                       user_login: 'mdf')

			#from label to dto >>>> number => barcode, description => desc, text => name,
			#prefix => prefix, scope => project, suffix => suffix

			#barcode is plate.barcode.to_i
			#desc is user_login + batch.output_plate_purpose.name + study.gsub("_", " ").gsub("-"," ")
			#name is study_name => plate_purpose.name.to_s
			#project == description


			assert_equal 9168090, barcode_label_dto.barcode
	    assert_equal 'mdf  Gen Ctrl', barcode_label_dto.desc
	    assert_equal 'Stock Plate', barcode_label_dto.name
	    assert_equal 'DN', barcode_label_dto.prefix
	    assert_equal 'mdf  Gen Ctrl', barcode_label_dto.project
	    assert_equal 134443, barcode_label_dto.suffix
		end
	end

	context "printing from sample manifest controller/model" do

		#number is plate.barcode
		#study is sample_manifest.study.abbreviation
		#suffix is plate.parent.try(:barcode)
		#prefix is plate.barcode_prefix.prefix

		setup do
			@label  = Sanger::Barcode::Printing::Label.new number: 9168101, study: "3792STDY", suffix: nil, prefix: "DN"
		end

		should 'it should have barcode name and barcode description' do
			#barcode_name is study.gsub("_", " ").gsub("-"," ")
			#barcode_description is "#{barcode_name}_#{number}" => study + number =>
			#=> sample_manifest.study.abbreviation + plate.barcode

			assert_equal '3792STDY', label.barcode_name
			assert_equal "3792STDY_9168101", label.barcode_description
		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#1 is barcode_printer.printer_type_id
			#prefix is Plate.prefix
			#study_name is PlatePurpose.stock_plate_purpose.name.to_s

			barcode_label_dto = label.printable(1, prefix: 'DN',
                   type: 'long',
                   study_name: 'Stock Plate',
                   user_login: nil)

			#from label to dto >>>> number => barcode, description => desc, text => name,
			#prefix => prefix, scope => project, suffix => suffix

			#barcode is plate.barcode.to_i
			#desc is barcode_description => sample_manifest.study.abbreviation + plate.barcode
			#name is study_name => PlatePurpose.stock_plate_purpose.name.to_s
			#project == description

			assert_equal 9168101, barcode_label_dto.barcode
	    assert_equal '3792STDY_9168101', barcode_label_dto.desc
	    assert_equal 'Stock Plate', barcode_label_dto.name
	    assert_equal 'DN', barcode_label_dto.prefix
	    assert_equal '3792STDY_9168101', barcode_label_dto.project
	    assert_equal nil, barcode_label_dto.suffix

		end
	end

end