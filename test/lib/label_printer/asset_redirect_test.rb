require 'test_helper'

class AssetGroupRedirectTest < ActiveSupport::TestCase

	attr_reader :asset_redirect, :labels, :assets, :asset

	context "print plates from asset group controller" do
		setup do
			asset1 = create :child_plate
			asset2 = create :child_plate
			asset3 = create :child_plate
			options = {printables: {"#{asset1.id}"=>"true", "#{asset2.id}" => "true", "#{asset3.id}" => "false"}}
			@asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)
			@assets = [asset1, asset2]

			@labels =	[{main_label:
									{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
									bottom_left: "#{asset1.sanger_human_barcode}",
									top_right: "#{asset1.prefix} #{asset1.barcode}",
									bottom_right: "#{asset1.name_for_label.to_s} #{asset1.barcode}",
									top_far_right: nil,
									barcode: "#{asset1.ean13_barcode}"}
								},
								{main_label:
									{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
									bottom_left: "#{asset2.sanger_human_barcode}",
									top_right: "#{asset2.prefix} #{asset2.barcode}",
									bottom_right: "#{asset2.name_for_label.to_s} #{asset2.barcode}",
									top_far_right: nil,
									barcode: "#{asset2.ean13_barcode}"}
								}
							]
		end

		should 'should return the right assets' do
			assert_equal assets, asset_redirect.assets
		end

		should 'should return the right labels' do
			assert_equal ({labels: {body: labels}}), asset_redirect.to_h
		end
	end

	context "print plate from asset controller #print_assets" do
		setup do
			@asset = create :child_plate
			options = {printables: asset}
			@asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)

			@labels =	[{main_label:
									{top_left: "#{Date.today.strftime("%e-%^b-%Y")}",
									bottom_left: "#{asset.sanger_human_barcode}",
									top_right: "#{asset.prefix} #{asset.barcode}",
									bottom_right: "#{asset.name_for_label.to_s} #{asset.barcode}",
									top_far_right: nil,
									barcode: "#{asset.ean13_barcode}"}
								}]
		end

		should 'should return the right assets' do
			assert_equal [asset], asset_redirect.assets
		end

		should 'should return the right labels' do
			assert_equal ({labels: {body: labels}}), asset_redirect.to_h
		end
	end

	context "print tubes from asset group controller" do
		setup do
			asset1 = create :sample_tube
			asset2 = create :sample_tube
			asset3 = create :sample_tube
			options = {printables: {"#{asset1.id}"=>"true", "#{asset2.id}" => "true", "#{asset3.id}" => "false"}}
			@asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)
			@assets = [asset1, asset2]

			@labels =	[{main_label:
									{top_line: asset1.name_for_label.to_s,
									middle_line: asset1.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: asset1.prefix,
									round_label_bottom_line: asset1.barcode,
									barcode: asset1.ean13_barcode}
								},
								{main_label:
									{top_line: asset2.name_for_label.to_s,
									middle_line: asset2.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: asset2.prefix,
									round_label_bottom_line: asset2.barcode,
									barcode: asset2.ean13_barcode}
								}
							]
		end

		should 'should return the right assets' do
			assert_equal assets, asset_redirect.assets
		end

		should 'should return the right labels' do
			assert_equal ({labels: {body: labels}}), asset_redirect.to_h
		end
	end

	context "print tube from asset controller #print_assets" do
		setup do
			@asset = create :sample_tube
			options = {printables: asset}
			@asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)

			@labels =	[{main_label:
									{top_line: asset.name_for_label.to_s,
									middle_line: asset.barcode,
									bottom_line: "#{Date.today.strftime("%e-%^b-%Y")}",
									round_label_top_line: asset.prefix,
									round_label_bottom_line: asset.barcode,
									barcode: asset.ean13_barcode}
								}]
		end

		should 'should return the right assets' do
			assert_equal [asset], asset_redirect.assets
		end

		should 'should return the right labels' do
			assert_equal ({labels: {body: labels}}), asset_redirect.to_h
		end
	end

end