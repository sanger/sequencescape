require "test_helper"

class PlatesControllerTest < ActionController::TestCase
  context "Plate" do
    setup do
      @controller = PlatesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @pico_assay_plate_creator    = Plate::Creator.find_by_name('Pico Assay Plates')
      @dilution_plates_creator     = Plate::Creator.find_by_name('Dilution Plates')
      @gel_dilution_plates_creator = Plate::Creator.find_by_name('Gel Dilution Plates')

      @barcode_printer = mock("printer abc")
      @barcode_printer.stubs(:id).returns(1)
      @barcode_printer.stubs(:name).returns("abc")
      @barcode_printer.stubs(:print_labels).returns(nil)
      @barcode_printer.stubs(:map).returns(["abc",1])
      @barcode_printer.stubs(:first).returns(@barcode_printer)
      BarcodePrinter.stubs(:find).returns(@barcode_printer)
      @plate_barcode = mock("plate barcode")
      @plate_barcode.stubs(:barcode).returns("1234567")
      PlateBarcode.stubs(:create).returns(@plate_barcode)
      @barcode_printer.stubs(:each).returns(@barcode_printer )
      @barcode_printer.stubs(:blank?).returns(true)
    end

    context "with a logged in user" do
      setup do
        @user = Factory :user, :barcode => 'ID100I'
        @user.is_administrator
        @controller.stubs(:current_user).returns(@user)

        @parent_plate  = Factory :plate, :barcode => "5678"
        @parent_plate2 = Factory :plate, :barcode => "1234"
        @parent_plate3 = Factory :plate, :barcode => "987"
      end

      context "#new" do
        setup do
          get :new
        end
        should_respond_with :success
        should_not_set_the_flash
      end

      context "#create" do

       context "with no source plates" do
          setup do
            post :create, :plates => {:creator_id => @gel_dilution_plates_creator.id, :barcode_printer => @barcode_printer.id, :user_barcode => '2470000100730'}
          end

          should_change("Plate.count", :by => 1) { Plate.count }
          should_respond_with :redirect
          should_set_the_flash_to /Created/
        end


        context "Create Pico Assay Plates" do
          context "with one source plate" do
            setup do
              @parent_raw_barcode = Barcode.calculate_barcode(Plate.prefix, @parent_plate.barcode.to_i)
              post :create, :plates => {:creator_id => @pico_assay_plate_creator.id, :barcode_printer => @barcode_printer.id, :source_plates =>"#{@parent_raw_barcode}", :user_barcode => '2470000100730' }
            end
            should_change("PicoAssayPlate.count", :by => 2) { PicoAssayPlate.count }
            should "add a child to the parent plate" do
              assert Plate.find(@parent_plate.id).children.first.is_a?(Plate)
              assert_equal PicoAssayPlatePurpose.find_by_name("Pico Assay A"), Plate.find(@parent_plate.id).children.first.plate_purpose
            end
            should_respond_with :redirect
            should_set_the_flash_to /Created/
          end

          context "with 3 source plates" do
            setup do
              @parent_raw_barcode  = Barcode.calculate_barcode(Plate.prefix, @parent_plate.barcode.to_i)
              @parent_raw_barcode2 = Barcode.calculate_barcode(Plate.prefix, @parent_plate2.barcode.to_i)
              @parent_raw_barcode3 = Barcode.calculate_barcode(Plate.prefix, @parent_plate3.barcode.to_i)
              post :create, :plates => {:creator_id => @pico_assay_plate_creator.id, :barcode_printer => @barcode_printer.id, :source_plates =>"#{@parent_raw_barcode}\n#{@parent_raw_barcode2}\t#{@parent_raw_barcode3}", :user_barcode => '2470000100730'}
            end
            should_change("PicoAssayPlate.count", :by => 6) { PicoAssayPlate.count }
            should "have child plates" do
              [@parent_plate, @parent_plate2, @parent_plate3].each do  |plate|
                assert Plate.find(plate.id).children.first.is_a?(Plate)
                assert_equal PicoAssayPlatePurpose.find_by_name("Pico Assay A"), Plate.find(plate.id).children.first.plate_purpose
              end
            end
            should_respond_with :redirect
            should_set_the_flash_to /Created/
          end
        end

      end
    end
  end
end
