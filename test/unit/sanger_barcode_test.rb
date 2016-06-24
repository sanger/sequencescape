require 'test_helper'

class SangerBarcodeTest < ActiveSupport::TestCase

	attr_reader :label

	context "printing plate labels from plate controller/ plate creator" do

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
			label_dto = label.printable(1, prefix: 'DN',
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


			assert_equal 9168090, label_dto.barcode
	    assert_equal 'mdf  Gen Ctrl', label_dto.desc
	    assert_equal 'Stock Plate', label_dto.name
	    assert_equal 'DN', label_dto.prefix
	    assert_equal 'mdf  Gen Ctrl', label_dto.project
	    assert_equal 134443, label_dto.suffix
		end
	end

	context "printing plate labels (rapid core) from sample manifest controller/model" do

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

			label_dto = label.printable(1, prefix: 'DN',
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

			assert_equal 9168101, label_dto.barcode
	    assert_equal '3792STDY_9168101', label_dto.desc
	    assert_equal 'Stock Plate', label_dto.name
	    assert_equal 'DN', label_dto.prefix
	    assert_equal '3792STDY_9168101', label_dto.project
	    assert_equal nil, label_dto.suffix

		end
	end

	context "printing plate labels from batches controller" do

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

			label_dto = label.printable(1, prefix: 'DN',
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

			assert_equal 434938, label_dto.barcode
	    assert_equal 'test Stock Plate 434938', label_dto.desc
	    assert_equal "WTCCC", label_dto.name
	    assert_equal 'DN', label_dto.prefix
	    assert_equal 'test Stock Plate 434938', label_dto.project
	    assert_equal nil, label_dto.suffix

		end


	end

	context "printing plate labels from assets controller/ asset groups controller" do

		#number is plate.barcode
		#study is plate.name_for_label.to_s
		#suffix is ""
		#prefix is plate.prefix

		setup do
			@label  = Sanger::Barcode::Printing::Label.new number: 434938, study: "Cherrypicked 434938", suffix: nil, prefix: "DN"
		end

		should 'it should have barcode name and barcode description' do
			#barcode_name is study.gsub("_", " ").gsub("-"," ")
			#barcode_description is "#{barcode_name}_#{number}" => study + number =>
			#=> plate.name_for_label.to_s + plate.barcode

			assert_equal 'Cherrypicked 434938', label.barcode_name
			assert_equal "Cherrypicked 434938_434938", label.barcode_description
		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#1 is barcode_printer.printer_type_id
			#prefix is plate.prefix

			label_dto = label.printable(1, prefix: 'DN', type: "short")

			#from label to dto >>>> number => barcode, description => desc (something that usually goes bottom right),
			#text => name (something that usually goes top right), prefix => prefix, scope => project, suffix => suffix
			#(something that usually goes top far right)

			#barcode is plate.barcode.to_i
			#desc is barcode_description => plate.name_for_label.to_s + plate.barcode
			#name is barcode_text(default_prefix) => plate.prefix + plate.barcode
			#project == description

			assert_equal 434938, label_dto.barcode
	    assert_equal 'Cherrypicked 434938_434938', label_dto.desc
	    assert_equal 'DN 434938', label_dto.name
	    assert_equal 'DN', label_dto.prefix
	    assert_equal 'Cherrypicked 434938_434938', label_dto.project
	    assert_equal nil, label_dto.suffix

		end
	end

	context "printing plate labels from sequenom qc plates controller/model" do

		#number is plate.barcode
		#study is nil
		#suffix is plate.plate_purpose.name => PlatePurpose.find_by_name("Sequenom").name
		#prefix is plate.prefix

		setup do
			@label  = Sanger::Barcode::Printing::Label.new number: 9168137, suffix: "Sequenom", prefix: "DN"
		end

		should 'it should have barcode name and barcode description' do
			#barcode_name is nil
			#barcode_description is "#{barcode_name}_#{number}" => study + number =>
			#=> nil + plate.barcode

			assert_equal nil, label.barcode_name
			assert_equal "_9168137", label.barcode_description
		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#1 is barcode_printer.printer_type_id
			#prefix is plate.prefix
			#study_name is plate.label_text_top => plate.plate_label(2) + plate.plate_label(3) =>
			#=> plate.name.match(/^([^\d]+)(\d+)?_(\d+)?_(\d+)?_(\d+)?_(\d+)$/) [2] [3] =>
			#=> plate.name is "#{plate_prefix}#{plate_number(input_plate_names)}#{plate_date}"
			#=> input_plate_names are input plates ean13_barcodes, plate_number converts them to
			# short barcodes, so it is basically first and second input plates barcodes
			#user_login is plate.label_text_bottom => plate_label(4) plate_label(5) =>
			#=> same logic as above => third and fourth input plates barcodes

			label_dto = label.printable(1, prefix: 'DN', type: 'long', study_name: "134443  9168137", user_login: "163993  160200 ")

			#from label to dto >>>> number => barcode, description => desc (something that usually goes bottom right),
			#text => name (something that usually goes top right), prefix => prefix, scope => project, suffix => suffix
			#(something that usually goes top far right)

			#barcode is plate.barcode.to_i
			#desc is barcode_description => plate.name_for_label.to_s + plate.barcode
			#name is barcode_text(default_prefix) => plate.prefix + plate.barcode
			#project == description

			assert_equal 9168137, label_dto.barcode
	    assert_equal "163993  160200   ", label_dto.desc
	    assert_equal "134443  9168137", label_dto.name
	    assert_equal "DN", label_dto.prefix
	    assert_equal "163993  160200   ", label_dto.project
	    assert_equal "Sequenom", label_dto.suffix

		end
	end

	context "printing tube label from sample_manifest controller" do

		#number is sample_tube.barcode => sample.assets.first.barcode
		#study is sample.sanger_sample_id, later changed to sample_manifest.study.abbreviation
		#suffix is ""
		#prefix is sample_tube.prefix, sample.assets.first.prefix

		setup do
			@label  = Sanger::Barcode::Printing::Label.new number: "740500", study: "3792STDY6319922", suffix: "", prefix: "NT"
		end

		should 'it should have barcode name and barcode description' do
			#barcode_name is study.gsub("_", " ").gsub("-"," ")
			#barcode_description is "#{barcode_name}_#{number}" => study + number =>
			#=> sample.sanger_sample_id + sample_tube.barcode

			assert_equal "3792STDY6319922", label.barcode_name
			assert_equal "3792STDY6319922_740500", label.barcode_description
		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#2 is barcode_printer.printer_type_id
			#prefix is sample_tube.prefix
			label.study = "3792STDY"
			label_dto = label.printable(2, prefix: 'NT', type: "short")

			#from label to dto >>>> number => barcode, description => desc (something that usually goes to top and middle lines),
			#text => name (something that goes on round label), prefix => prefix, scope => project, suffix => suffix

			#barcode is sample_tube.barcode.to_i
			#desc is barcode_description => sample_manifest.study.abbreviation + sample_tube.barcode
			#name is barcode_text(default_prefix) => sample_tube.prefix + sample_tube.barcode
			#project == description

			assert_equal 740500, label_dto.barcode
	    assert_equal "3792STDY_740500", label_dto.desc
	    assert_equal "NT 740500", label_dto.name
	    assert_equal "NT", label_dto.prefix
	    assert_equal "3792STDY_740500", label_dto.project
	    assert_equal "", label_dto.suffix

		end
	end

	context "printing tube labels from batches controller" do

		#study differs depending on params[:stock], @batch.multiplexed? and request.tag_number.nil?
		#study is request.target_asset.children.first.name, if params[:stock] and @batch.multiplexed?
		#study is request.target_asset.stock_asset.name, if params[:stock] and not @batch.multiplexed?
		#study is "(#{request.tag_number}) #{request.target_asset.id}", if no params[:stock], @batch.multiplexed? and request.tag_number is not nill
		#study is request.target_asset.name, if no params[:stock], @batch.multiplexed? and request.tag_number is nill
		#study is request.target_asset.tube_name, if no params[:stock] and not @batch.multiplexed?

		#number differs depending on params[:stock] and @batch.multiplexed?
		#number is request.target_asset.children.first.barcode, if params[:stock] and @batch.multiplexed?
		#number is request.target_asset.stock_asset.barcode, if params[:stock] and not @batch.multiplexed?
		#number is request.target_asset.barcode (requests ids are in params[printables]), if no params[:stock]


		setup do
			@label  = Sanger::Barcode::Printing::Label.new number: "739884", study: '6295001'
		end

		should 'it should have barcode name and barcode description' do
			#barcode_name is study.gsub("_", " ").gsub("-"," ") => up
			#barcode_description is "#{barcode_name}_#{number}" => up

			assert_equal "6295001", label.barcode_name
			assert_equal "6295001_739884", label.barcode_description

		end

		should '#printable should create an instance of BarcodeLabelDTO' do
			#2 is barcode_printer.printer_type_id
			#prefix is @batch.requests.first.target_asset.prefix

			label_dto = label.printable(2, prefix: 'NT', type: 'short')

			#from label to dto >>>> number => barcode, description => desc (something that usually goes to top and middle lines),
			#text => name (something that goes on round label), prefix => prefix, scope => project, suffix => suffix

			#barcode is number
			#desc is barcode_description
			#name is text => prefix + number.to_s
			#project == description

			assert_equal 739884, label_dto.barcode
	    assert_equal '6295001_739884', label_dto.desc
	    assert_equal "NT 739884", label_dto.name
	    assert_equal 'NT', label_dto.prefix
	    assert_equal '6295001_739884', label_dto.project
	    assert_equal nil, label_dto.suffix

		end


	end

end