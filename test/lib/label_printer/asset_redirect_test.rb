require 'test_helper'

class AssetGroupRedirectTest < ActiveSupport::TestCase
  attr_reader :asset_redirect, :labels, :assets, :asset, :barcode1, :barcode2, :barcode3, :prefix, :asset_name

  context 'print plates from asset group controller' do
    setup do
      @asset_name = 'Plate name'
      @prefix = 'DN'
      @barcode1 = '11111'
      @barcode2 = '22222'
      @barcode3 = '33333'
      asset1 = create :child_plate, barcode: barcode1
      asset2 = create :child_plate, barcode: barcode2
      asset3 = create :child_plate, barcode: barcode3
      options = { printables: { (asset1.id).to_s => 'true', (asset2.id).to_s => 'true', (asset3.id).to_s => 'false' } }
      @asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)
      @assets = [asset1, asset2]

      @labels = [{ main_label:
                  { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
                    bottom_left: (asset1.sanger_human_barcode).to_s,
                    top_right: "#{prefix} #{barcode1}",
                    bottom_right: "#{asset_name} #{barcode1}",
                    top_far_right: nil,
                    barcode: (asset1.ean13_barcode).to_s }
                },
                { main_label:
                  { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
                    bottom_left: (asset2.sanger_human_barcode).to_s,
                    top_right: "#{prefix} #{barcode2}",
                    bottom_right: "#{asset_name} #{barcode2}",
                    top_far_right: nil,
                    barcode: (asset2.ean13_barcode).to_s }
                }
              ]
    end

    should 'should return the right assets' do
      assert_equal assets, asset_redirect.assets
    end

    should 'should return the right labels' do
      assert_equal ({ labels: { body: labels } }), asset_redirect.to_h
    end
  end

  context 'print plate from asset controller #print_assets' do
    setup do
      @asset_name = 'Plate name'
      @prefix = 'DN'
      @barcode1 = '11111'
      @asset = create :child_plate, barcode: barcode1
      options = { printables: asset }
      @asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)

      @labels = [{ main_label:
                  { top_left: (Date.today.strftime('%e-%^b-%Y')).to_s,
                    bottom_left: (asset.sanger_human_barcode).to_s,
                    top_right: "#{prefix} #{barcode1}",
                    bottom_right: "#{asset_name} #{barcode1}",
                    top_far_right: nil,
                    barcode: (asset.ean13_barcode).to_s }
                }]
    end

    should 'should return the right assets' do
      assert_equal [asset], asset_redirect.assets
    end

    should 'should return the right labels' do
      assert_equal ({ labels: { body: labels } }), asset_redirect.to_h
    end
  end

  context 'print tubes from asset group controller' do
    setup do
      @prefix = 'NT'
      @barcode1 = '11111'
      @barcode2 = '22222'
      @barcode3 = '33333'
      @asset_name = 'tube name'
      asset1 = create :sample_tube, barcode: barcode1, name: asset_name
      asset2 = create :sample_tube, barcode: barcode2, name: asset_name
      asset3 = create :sample_tube, barcode: barcode3
      options = { printables: { (asset1.id).to_s => 'true', (asset2.id).to_s => 'true', (asset3.id).to_s => 'false' } }
      @asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)
      @assets = [asset1, asset2]
      @labels = [{ main_label:
                  { top_line: asset_name,
                    middle_line: barcode1,
                    bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
                    round_label_top_line: prefix,
                    round_label_bottom_line: barcode1,
                    barcode: asset1.ean13_barcode }
                },
                { main_label:
                  { top_line: asset_name,
                    middle_line: barcode2,
                    bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
                    round_label_top_line: prefix,
                    round_label_bottom_line: barcode2,
                    barcode: asset2.ean13_barcode }
                }
              ]
    end

    should 'should return the right assets' do
      assert_equal assets, asset_redirect.assets
    end

    should 'should return the right labels' do
      assert_equal ({ labels: { body: labels } }), asset_redirect.to_h
    end
  end

  context 'print tube from asset controller #print_assets' do
    setup do
      @prefix = 'NT'
      @barcode1 = '11111'
      @asset_name = 'tube name'
      @asset = create :sample_tube, barcode: barcode1, name: asset_name
      options = { printables: asset }
      @asset_redirect = LabelPrinter::Label::AssetRedirect.new(options)

      @labels = [{ main_label:
                  { top_line: asset_name,
                    middle_line: barcode1,
                    bottom_line: (Date.today.strftime('%e-%^b-%Y')).to_s,
                    round_label_top_line: prefix,
                    round_label_bottom_line: barcode1,
                    barcode: asset.ean13_barcode }
                }]
    end

    should 'should return the right assets' do
      assert_equal [asset], asset_redirect.assets
    end

    should 'should return the right labels' do
      assert_equal ({ labels: { body: labels } }), asset_redirect.to_h
    end
  end
end
