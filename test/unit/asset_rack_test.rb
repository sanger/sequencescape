require "test_helper"

class AssetRackTest < ActiveSupport::TestCase

  context "Rack priority" do
    setup do
      @rack = Factory :full_asset_rack
      user = Factory(:user)
      @rack.wells[0...3].each_with_index do |well,index|
        Factory :request, :target_asset=>well, :submission=>Submission.create!(:priority => (index%2)+1, :user => user)
      end
    end

    should "inherit the highest submission priority" do
      assert_equal 2, @rack.priority
    end
  end

  context "Rack wells" do
    setup do
      @rack = Factory :fuller_asset_rack
    end

    should "find the right well" do
      [
        ['A1','A1','S1'],
        ['A2','A2','S1'],
        ['B1','A1','S2'],
        ['B2','A2','S2']
      ].each do |rack_cord,strip_location,strip_cord|
        well = @rack.wells.located_at(rack_cord)
        assert_equal 1, well.count, "Found #{well.count == 0 ? 'no' : 'too many'} wells"
        assert_equal strip_location, well.first.plate.map.description, "Found the wrong strip for #{rack_cord}"
        assert_equal strip_cord, well.first.map.description, "Found the wrong tube on the strip for #{rack_cord}"
      end
    end
  end

  context "#create" do
    setup do
      PlateBarcode.stubs(:create).returns(OpenStruct.new(:barcode =>1))
      @purpose = Factory :asset_rack_purpose
      @rack =  @purpose.create!
    end

    should "create strip tubes" do
      assert_equal 12,   @rack.strip_tubes.count
      assert_equal nil,  @rack.strip_tubes.first.barcode
      assert_equal 'LS', @rack.strip_tubes.first.barcode_prefix.prefix
    end

  end


  context "A Rack" do
    setup do
      @rack = Factory :asset_rack
    end

    context "without attachments" do
      should "not report any qc_data" do
        assert @rack.qc_files.empty?
      end
    end

    context "with attached qc data" do
      setup do
        File.open("test/data/manifests/mismatched_plate.csv") do |file|
          @rack.add_qc_file file
        end
      end

      should "return any qc data" do
        assert @rack.qc_files.count ==1
        File.open("test/data/manifests/mismatched_plate.csv") do |file|
          assert_equal file.read, @rack.qc_files.first.uploaded_data.file.read
        end
      end
    end

   context "with multiple attached qc data" do
      setup do
        File.open("test/data/manifests/mismatched_plate.csv") do |file|
          @rack.add_qc_file file
          @rack.add_qc_file file
        end
      end

      should "return multiple qc data" do
        assert @rack.qc_files.count ==2
      end
    end

  end



end


