# frozen_string_literal: true

require 'test_helper'
require './spec/lib/mock_parser'

class PlateTest < ActiveSupport::TestCase
  def create_plate_with_fluidigm(plate_barcode, fluidigm_barcode)
    purpose = create(:plate_purpose)
    purpose.create!(
      :do_not_create_wells,
      name: "Cherrypicked #{plate_barcode}",
      size: 192,
      barcode: plate_barcode,
      fluidigm_barcode: fluidigm_barcode
    )
  end

  context '' do
    context '#infinium_barcode=' do
      setup do
        @plate = Plate.new
        @plate.infinium_barcode = 'AAA'
      end

      should 'set the infinium barcode' do
        assert_equal 'AAA', @plate.infinium_barcode
      end
    end

    context '#fluidigm_barcode' do
      setup do
        @plate_barcode = build(:plate_barcode)
        PlateBarcode.stubs(:create_barcode).returns(@plate_barcode)
      end

      should 'check that I cannot create a plate with a fluidigm barcode different from 10 characters' do
        assert_raises(ActiveRecord::RecordInvalid) { create_plate_with_fluidigm(@plate_barcode.barcode, '12345678') }
      end
      should 'check that I can create a plate with a fluidigm barcode equal to 10 characters' do
        assert_nothing_raised { create_plate_with_fluidigm(@plate_barcode.barcode, '1234567890') }
      end
    end
  end

  context '#iteration' do
    setup do
      @parent = create(:plate, created_at: 6.hours.ago)
      tested_purpose = create(:plate_purpose)
      @parent.children << @child_a = create(:plate, plate_purpose: tested_purpose, created_at: 5.hours.ago)
      @parent.children << @child_b = create(:plate, plate_purpose: tested_purpose, created_at: 4.hours.ago)
      @child_b.children << @dummy = create(:plate, plate_purpose: tested_purpose, created_at: 3.hours.ago)
      @parent.children << @child_c = create(:plate, plate_purpose: tested_purpose, created_at: 1.hour.ago)
      @parent.children << @child_d = create(:plate)
    end

    should 'correctly calculate iterations' do
      assert_equal 1, @child_a.reload.iteration, 'First child is not iteration 1'
      assert_equal 2, @child_b.reload.iteration, 'Second child is not iteration 2'
      assert_equal 3, @child_c.reload.iteration, 'Third child created after grandchild is not iteration 3'
      assert_equal 1, @child_d.reload.iteration, 'First child of another purpose is not iteration 1'
    end
  end

  context '#plate_ids_from_requests' do
    setup do
      @plate1 = create(:plate, :with_wells, well_count: 1)
      @well1 = @plate1.wells.first
      @request1 = create(:well_request, asset: @well1)
    end

    context 'with 1 request' do
      context 'with a valid well asset' do
        should 'return correct plate ids' do
          assert_includes Plate.plate_ids_from_requests([@request1]), @plate1.id
        end
      end
    end

    context 'with 2 requests on the same plate' do
      setup do
        @well2 = Well.new
        @plate1.wells << @well2
        @request2 = create(:well_request, asset: @well2)
      end
      context 'with a valid well assets' do
        should 'return a single plate ID' do
          assert_includes Plate.plate_ids_from_requests([@request1, @request2]), @plate1.id
          assert_includes Plate.plate_ids_from_requests([@request2, @request1]), @plate1.id
        end
      end
    end

    context 'with multiple requests on different plates' do
      setup do
        @well2 = Well.new
        @plate2 = create(:plate, :with_wells, well_count: 1)
        @well2 = @plate2.wells.first
        @request2 = create(:well_request, asset: @well2)
        @well3 = Well.new
        @plate1.wells << @well3
        @request3 = create(:well_request, asset: @well3)
      end
      context 'with a valid well assets' do
        should 'return 2 plate IDs' do
          assert_includes Plate.plate_ids_from_requests([@request1, @request2, @request3]), @plate1.id
          assert_includes Plate.plate_ids_from_requests([@request1, @request2, @request3]), @plate2.id
          assert_includes Plate.plate_ids_from_requests([@request3, @request1, @request2]), @plate1.id
          assert_includes Plate.plate_ids_from_requests([@request3, @request1, @request2]), @plate2.id
        end
      end
    end
  end

  context 'Plate priority' do
    setup do
      @plate = create(:transfer_plate)
      user = create(:user)
      @plate.wells.each_with_index do |well, index|
        create(:request, asset: well, submission: Submission.create!(priority: index + 1, user: user))
      end
    end

    should 'inherit the highest submission priority' do
      assert_equal 3, @plate.priority
    end
  end

  context 'A Plate' do
    setup { @plate = Plate.create! }

    context 'without attachments' do
      should 'not report any qc_data' do
        assert_empty @plate.qc_files
      end
    end

    context 'with attached qc data' do
      setup { File.open('test/data/manifests/mismatched_plate.csv') { |file| @plate.add_qc_file file } }

      should 'return any qc data' do
        assert_equal 1, @plate.qc_files.count
        File.open('test/data/manifests/mismatched_plate.csv') do |file|
          assert_equal file.read, @plate.qc_files.first.uploaded_data.file.read
        end
      end
    end

    context 'with multiple attached qc data' do
      setup do
        File.open('test/data/manifests/mismatched_plate.csv') do |file|
          @plate.add_qc_file file
          @plate.add_qc_file file
        end
      end

      should 'return multiple qc data' do
        assert_equal 2, @plate.qc_files.count
      end
    end
  end

  context 'with existing well data' do
    setup do
      @plate = create(:plate_with_empty_wells, well_count: 3)
      @plate.wells.first.set_concentration('12')
      @plate.wells.first.set_molarity('34')
      @plate.update_qc_values_with_parser(MockParser.new)
    end

    should 'update new wells' do
      well_b1 = @plate.wells.detect { |w| w.map_description == 'B1' }.reload
      well_c1 = @plate.wells.detect { |w| w.map_description == 'C1' }.reload

      assert_in_delta(2.0, well_b1.get_concentration)
      assert_in_delta(3.0, well_b1.get_molarity)
      assert_in_delta(4.0, well_c1.get_concentration)
      assert_in_delta(5.0, well_c1.get_molarity)
    end

    should 'create QcResults per well' do
      well_b1 = @plate.wells.detect { |w| w.map_description == 'B1' }.reload
      well_c1 = @plate.wells.detect { |w| w.map_description == 'C1' }.reload

      assert_equal 4, well_b1.qc_results.count
      assert_equal 4, well_c1.qc_results.count
      keys = well_b1.qc_results.map(&:key)

      assert_includes keys, 'Concentration'
      assert_includes keys, 'Molarity'
      assert_equal 'Mock parser', well_b1.qc_results.first.assay_type
      assert_equal '1.0', well_b1.qc_results.first.assay_version
    end

    should 'not create QcResults for missing wells' do
      well_a1 = @plate.wells.detect { |w| w.map_description == 'A1' }.reload

      assert_equal 0, well_a1.qc_results.count
    end

    should 'not clear existing data' do
      well_a1 = @plate.wells.detect { |w| w.map_description == 'A1' }.reload

      assert_in_delta(12.0, well_a1.get_concentration)
      assert_in_delta(34.0, well_a1.get_molarity)
    end
  end

  context '::with_descendants_owned_by' do
    setup do
      @user = create(:user)
      @source_plate = create(:source_plate)
      @child_plate = create(:child_plate, parent: @source_plate)
    end

    should 'find source plates with owners' do
      create(:plate_owner, user: @user, plate: @child_plate)

      assert_includes Plate.with_descendants_owned_by(@user), @source_plate
    end

    should 'not find plates without owners' do
      assert_not_includes Plate.with_descendants_owned_by(@user), @source_plate
    end

    should 'allow filtering of source plates' do
      plates = Plate.source_plates

      assert_includes plates, @source_plate
      assert_not_includes plates, @child_plate
    end
  end
end
