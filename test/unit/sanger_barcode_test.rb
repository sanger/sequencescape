require 'test_helper'

class SangerBarcodeTest < ActiveSupport::TestCase

	attr_reader :label

	#number is plate.barcode
	#study is plate.find_study_abbreviation_from_parent
	#suffix is plate.parent.try(:barcode)
	#prefix is plate.barcode_prefix.prefix

	def setup
		@label = Sanger::Barcode::Printing::Label.new number: 9168090, study: 'Gen_Ctrl', suffix: 134443, prefix: 'DN'
	end

	test "it should have options" do
		assert_equal 9168090, label.number
		assert_equal 'Gen_Ctrl', label.study
		assert_equal 134443,  label.suffix
		assert_equal 'DN', label.prefix
	end

	test 'it should have barcode name and barcode description' do
		assert_equal 'Gen Ctrl', label.barcode_name
		assert_equal 'Gen Ctrl_9168090', label.barcode_description
	end

	test '#printable should create an instance of BarcodeLabelDTO' do
		#1 is barcode_printer.printer_type_id
		#prefix is Plate.prefix
		#study_name is plate.plate_purpose.name.to_s
		#user_login is user.login
		barcode_label_dto = label.printable(1, prefix: 'DN',
                       type: 'long',
                       study_name: 'Stock Plate',
                       user_login: 'mdf')
		#barcode is plate.barcode.to_i
		#desc is user_login + batch.output_plate_purpose.name + study.gsub("_", " ").gsub("-"," ")
		#name is plate_purpose.name.to_s
		#project == description

		assert_equal 9168090, barcode_label_dto.barcode
    assert_equal 'mdf  Gen Ctrl', barcode_label_dto.desc
    assert_equal 'Stock Plate', barcode_label_dto.name
    assert_equal 'DN', barcode_label_dto.prefix
    assert_equal 'mdf  Gen Ctrl', barcode_label_dto.project
    assert_equal 134443, barcode_label_dto.suffix
	end

end