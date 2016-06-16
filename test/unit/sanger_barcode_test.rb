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

			#from label to dto >>>> number => barcode, description => desc (something that usually goes bottom right),
			#text => name (something that usually goes top right), prefix => prefix, scope => project, suffix => suffix
			#(something that usually goes top far right)

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

			#from label to dto >>>> number => barcode, description => desc (something that usually goes bottom right),
			#text => name (something that usually goes top right), prefix => prefix, scope => project, suffix => suffix
			#(something that usually goes top far right)

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

	context "printing from batches controller" do

		#number is @batch.plate_group_barcodes, key(plate) barcode, (params[:printable] key)
		#study is @batch.plate_group_barcodes, key(plate) barcode, (params[:printable] key)
		#batch is @batch

		setup do
			study = create :study
      project = create :project
      asset = create :empty_sample_tube
      order_role = Order::OrderRole.new role: 'test'

			order = create :order, order_role: order_role, study: study, assets: [asset], project: project
   		request = create :well_request, asset: (create :well_with_sample_and_plate), target_asset: (create :well_with_sample_and_plate), order: order

   		batch = create :batch
   		batch.requests << request

			@label  = Sanger::Barcode::Printing::Label.new number: '434938', study: '434938', batch: batch
		end

		should 'it should have barcode name and barcode description' do
			#barcode_name is study.gsub("_", " ").gsub("-"," ") => plate.barcode
			#barcode_description is "#{barcode_name}_#{number}" => plate.barcode _ plate.barcode
			#output_plate_purpose is batch.output_plate_purpose
			#output_plate_role is batch.output_plate_role
			assert_equal "434938", label.barcode_name
			assert_equal "434938_434938", label.barcode_description
			assert_equal "Stock Plate", label.output_plate_purpose
			assert_equal "test", label.output_plate_role
		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#1 is barcode_printer.printer_type_id
			#prefix is "DN", hardcoded
			#study_name is @batch.study.abbreviation
			#user_login current_user.login

			barcode_label_dto = label.printable(1, prefix: 'DN',
                   type: 'cherrypick',
                   study_name: "WTCCC",
                   user_login: 'admin')

			#from label to dto >>>> number => barcode, description => desc (something that usually goes bottom right),
			#text => name (something that usually goes top right), prefix => prefix, scope => project, suffix => suffix
			#(something that usually goes top far right)

			#barcode is plate.barcode.to_i (@batch.plate_group_barcodes, key(plate) barcode)
			#desc is barcode_description => batch.output_plate_role + batch.output_plate_purpose + plate.barcode
			#name is study_name => batch.study.abbreviation
			#project == description

			assert_equal 434938, barcode_label_dto.barcode
	    assert_equal 'test Stock Plate 434938', barcode_label_dto.desc
	    assert_equal "WTCCC", barcode_label_dto.name
	    assert_equal 'DN', barcode_label_dto.prefix
	    assert_equal 'test Stock Plate 434938', barcode_label_dto.project
	    assert_equal nil, barcode_label_dto.suffix

		end


	end

end