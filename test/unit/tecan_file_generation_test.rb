# frozen_string_literal: true

require 'test_helper'
require 'tecan_file_generation'

class Sanger::Robots::Tecan::GeneratorTest < ActiveSupport::TestCase
  context 'Sanger::Robots::Tecan::Generator' do
    setup do
      asset_shape = AssetShape.find_by(name: 'Standard')
      purpose = Purpose.create!(name: 'test purpose', target_type: 'Plate', size: 96, asset_shape_id: asset_shape.id)
      plate = Plate.create!(plate_purpose_id: purpose.reload.id)
      @barcode = Barcode.create!(asset_id: plate.id, barcode: 'NT17687E', format: 0)
    end

    @testcases = []
    # original
    file = File.open('test/data/tecan/original.gwl', 'rb')
    expected_output = file.read
    data_object = {
      'user' => 'xyz987',
      'time' => 'Tue Sep 29 11:00:42 2009',
      'source' => {
        '95020' => {
          'name' => 'ABgene 0765',
          'plate_size' => 96
        }
      },
      'destination' => {
        'NT17687E' => {
          'name' => 'ABgene 0800',
          'plate_size' => 96,
          'mapping' => [
            { 'src_well' =>  %w[95020 B7], 'dst_well' => 'A1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 C7], 'dst_well' => 'B1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 D7], 'dst_well' => 'C1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 E7], 'dst_well' => 'D1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 H7], 'dst_well' => 'E1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 D8], 'dst_well' => 'F1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 E8], 'dst_well' => 'G1', 'volume' => 6.77, 'buffer_volume' => 6.23 },
            { 'src_well' =>  %w[95020 A8], 'dst_well' => 'H1', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 G8], 'dst_well' => 'A2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 H8], 'dst_well' => 'B2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 A9], 'dst_well' => 'C2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 B9], 'dst_well' => 'D2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 C9], 'dst_well' => 'E2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 D9], 'dst_well' => 'F2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 E9], 'dst_well' => 'G2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 F9], 'dst_well' => 'H2', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 G9], 'dst_well' => 'A3', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' =>  %w[95020 H9], 'dst_well' => 'B3', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 C10], 'dst_well' => 'C3', 'volume' => 9.48, 'buffer_volume' => 3.52 },
            { 'src_well' => %w[95020 E10], 'dst_well' => 'D3', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 F10], 'dst_well' => 'E3', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 H10], 'dst_well' => 'F3', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 D11], 'dst_well' => 'G3', 'volume' => 6.91, 'buffer_volume' => 6.09 },
            { 'src_well' => %w[95020 A11], 'dst_well' => 'H3', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 B11], 'dst_well' => 'A4', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 E11], 'dst_well' => 'B4', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 G11], 'dst_well' => 'C4', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 B12], 'dst_well' => 'D4', 'volume' => 7.83, 'buffer_volume' => 5.17 },
            { 'src_well' => %w[95020 A12], 'dst_well' => 'E4', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 C12], 'dst_well' => 'F4', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 D12], 'dst_well' => 'G4', 'volume' => 13, 'buffer_volume' => 0.0  },
            { 'src_well' => %w[95020 F12], 'dst_well' => 'H4', 'volume' => 13, 'buffer_volume' => 0.0  }
          ]
        }
      }
    }

    @testcases << { data_object: data_object, expected_output: expected_output }

    file = File.open('test/data/tecan/NT17687E.gwl', 'rb')
    expected_output = file.read
    data_object = {
      'user' => 'xyz987',
      'time' => 'Fri Nov 27 10:11:13 2009',
      'source' => {
        '122289' => {
          'name' => 'ABgene 0765',
          'plate_size' => 96
        },
        '80785' => {
          'name' => 'ABgene 0765',
          'plate_size' => 96
        },
        '122290' => {
          'name' => 'ABgene 0765',
          'plate_size' => 96
        }
      },
      'destination' => {
        'NT17687E' => {
          'name' => 'ABgene 0800',
          'plate_size' => 96,
          'mapping' => [
            { 'src_well' => %w[122289 G7], 'dst_well' => 'D4', 'volume' => 3.33, 'buffer_volume' => 9.67 },
            { 'src_well' =>  %w[80785 A1],  'dst_well' => 'E4', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' =>  %w[122289 H7], 'dst_well' => 'F4', 'volume' => 3.27, 'buffer_volume' => 9.73 },
            { 'src_well' =>  %w[122290 A1], 'dst_well' => 'E9', 'volume' => 2.8, 'buffer_volume' => 10.2 },
            { 'src_well' =>  %w[122290 B1], 'dst_well' => 'F9', 'volume' => 4.08, 'buffer_volume' => 8.92 }
          ]
        }
      }
    }

    @testcases << { data_object: data_object, expected_output: expected_output }

    file = File.open('test/data/tecan/pooled_cherrypick.gwl', 'rb')
    expected_output = file.read
    data_object = {
      'user' => 'xyz987',
      'time' => 'Fri Nov 27 10:11:13 2009',
      'source' => {
        '1220415828863' => {
          'name' => 'ABgene 0765',
          'plate_size' => 96
        }
      },
      'destination' => {
        'NT17687E' => {
          'name' => 'ABgene 0800',
          'plate_size' => 96,
          'mapping' => [
            { 'src_well' => %w[1220415828863 A1], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[1220415828863 A2], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[1220415828863 A3], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[1220415828863 A4], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 },
            { 'src_well' => %w[1220415828863 A5], 'dst_well' => 'A1', 'volume' => 13.0, 'buffer_volume' => 0.0 }
          ]
        }
      }
    }

    @testcases << { data_object: data_object, expected_output: expected_output }

    @testcases.each_with_index do |testcase, index|
      context ".mapping for testcase #{index}" do
        setup do
          @data_object = (testcase)[:data_object]
          @expected_output = (testcase)[:expected_output]
        end

        context 'when mapping wells from 1 96 well source plate to 1 96 well destination plate' do
          should 'return a String object' do
            assert_kind_of String, Sanger::Robots::Tecan::Generator.mapping(@data_object, 13)
          end

          should 'generate the expected output' do
            assert_equal @expected_output, Sanger::Robots::Tecan::Generator.mapping(@data_object, 13)
          end

          should 'have a header section' do
            assert_match(
              /^C;\nC; This file created by (.+?) on (.+?)\nC;\n/,
              Sanger::Robots::Tecan::Generator.mapping(@data_object, 13)
            )
          end

          should 'contain buffers' do
            assert_match(
              /(?:A;BUFF;;.*?\nD;DEST[0-9].*?\nW;\n)?/,
              Sanger::Robots::Tecan::Generator.mapping(@data_object, 13)
            )
          end

          should 'contain a footer' do
            assert_match(
              /C;\n(C; SCRC[0-9] = [0-9]+\n)+C;\nC; DEST[0-9] = NT[0-9]+E\n$/,
              Sanger::Robots::Tecan::Generator.mapping(@data_object, 13)
            )
          end
        end
        context 'when passed invalid object' do
          should 'throw an ArgumentError' do
            assert_raises ArgumentError do
              Sanger::Robots::Tecan::Generator.mapping nil, nil
            end
          end
        end
      end
    end

    context '#barcode_to_plate_index' do
      setup do
        @barcodes = { '1111' => 'aaa', '5555' => 'tttt', '4444' => 'bbbb', '7777' => 'zzzz' }
      end
      should 'remap barcode ids to start at 1' do
        @plate_index_lookup = Sanger::Robots::Tecan::Generator.barcode_to_plate_index(@barcodes)
        @barcodes.each do |key, _value|
          assert @plate_index_lookup[key].is_a?(Integer)
          assert @plate_index_lookup[key] > 0
          assert @plate_index_lookup[key] <= @barcodes.length
        end
        assert_equal @plate_index_lookup.length, @barcodes.length
      end
    end
  end

  context '#source_barcode_to_plate_index' do
    setup do
      asset_shape = AssetShape.find_by(name: 'Fluidigm192')
      purpose = Purpose.create!(name: 'test purpose', target_type: 'Plate', size: 192, asset_shape_id: asset_shape.id)
      plate = Plate.create!(plate_purpose_id: purpose.reload.id, size: 192)
      @barcode = Barcode.create!(asset_id: plate.id, barcode: 'NT17695E', format: 0)

      @barcodes = {
        'NT17695E' =>
          { 'mapping' => [
            { 'src_well' =>  %w[88888 A11], 'dst_well' => 'S011', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' =>  %w[66666 H7], 'dst_well' => 'S093', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' =>  %w[99999 C7], 'dst_well' => 'S031', 'volume' => 13, 'buffer_volume' => 0.0 },
            { 'src_well' =>  %w[88888 A1], 'dst_well' => 'S001', 'volume' => 13, 'buffer_volume' => 0.0 }
          ] }
      }
      @expected_order = { '88888' => 1, '99999' => 2, '66666' => 3 }
      @source_index = Sanger::Robots::Tecan::Generator.source_barcode_to_plate_index(@barcodes)
    end

    should 'remap barcodes to start at 1' do
      @expected_order.each do |source_barcode, _index|
        assert @source_index[source_barcode].is_a?(Integer)
        assert @source_index[source_barcode] > 0
        assert @source_index[source_barcode] <= @expected_order.length
      end
    end
    should 'order source plates by destination well barcode to match the way the robot picks' do
      assert_equal @expected_order, @source_index
    end
  end

  context '#sort_mapping_by_destination_well' do
    setup do

      asset_shape = AssetShape.find_by(name: 'Fluidigm192')
      purpose = Purpose.create!(name: 'test purpose', target_type: 'Plate', size: 192, asset_shape_id: asset_shape.id)
      plate = Plate.create!(plate_purpose_id: purpose.reload.id, size: 192)
      @barcode = Barcode.create!(asset_id: plate.id, barcode: 'NT17695E', format: 0)

      @mapping = [
        { 'src_well' =>  %w[88888 A11], 'dst_well' => 'S011', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' =>  %w[66666 H7], 'dst_well' => 'S093', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' =>  %w[99999 C7], 'dst_well' => 'S031', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' =>  %w[88888 A1], 'dst_well' => 'S001', 'volume' => 13, 'buffer_volume' => 0.0 }
      ]
      @expected_order = [
        { 'src_well' =>  %w[88888 A1], 'dst_well' => 'S001', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' =>  %w[88888 A11], 'dst_well' => 'S011', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' =>  %w[99999 C7], 'dst_well' => 'S031', 'volume' => 13, 'buffer_volume' => 0.0 },
        { 'src_well' =>  %w[66666 H7], 'dst_well' => 'S093', 'volume' => 13, 'buffer_volume' => 0.0 }
      ]
      @new_order = Sanger::Robots::Tecan::Generator.sort_mapping_by_destination_well(@barcode.barcode, @mapping)
    end

    should 'sort mapping by the destination well barcode' do
      assert_equal @expected_order, @new_order
    end
  end
end
