# frozen_string_literal: true

require 'test_helper'

class PlatesFromTubesControllerTest < ActionController::TestCase
  context 'Plates from Tubes' do
    setup do
      @controller = PlatesFromTubesController.new
      @request = ActionController::TestRequest.create(@controller)

      # Populating plate purposes
      @stock_plate_purpose = create(:plate_purpose, name: 'Stock Plate')
      @rna_stock_plate_purpose = create(:plate_purpose, name: 'scRNA Stock Plate')

      # Populating plate creators
      @stock_plate_creator = create(:plate_creator, name: 'Stock Plate', plate_purposes: [@stock_plate_purpose])
      @rna_stock_plate_creator =
        create(:plate_creator, name: 'scRNA Stock Plate', plate_purposes: [@rna_stock_plate_purpose])

      # Populating barcode printers
      @barcode_printer = create(:barcode_printer)

      # Stubbing the PmbClient
      LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
      LabelPrinter::PmbClient.stubs(:print).returns(200)
    end

    context 'with a logged in user' do
      setup do
        @user = FactoryBot.create(:user, swipecard_code: '1234567')
        @user.grant_administrator
        session[:user] = @user.id
      end

      # Happy path
      context 'on POST to create a stock plate' do
        setup do
          @tube1 = FactoryBot.create(:tube)
          @tube2 = FactoryBot.create(:tube)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          # Initial plate count in the in-memory database
          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes: "#{@tube1.barcodes.first}\r\n#{@tube2.barcodes.first}"
                 }
               }
        end

        should 'create a plate and increase the plate count' do
          assert_equal @plate_count + 1, Plate.count
        end
        should respond_with :ok
        should 'create a plate with the correct barcode' do
          assert_equal 'SQPD-1234567', Plate.last.barcodes.first.barcode
        end
      end

      context 'on POST to create an RNA plate' do
        setup do
          @tube1 = FactoryBot.create(:tube)
          @tube2 = FactoryBot.create(:tube)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          # Initial plate count in the in-memory database
          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'RNA Stock Plate',
                   source_tubes: "#{@tube1.barcodes.first}\r\n#{@tube2.barcodes.first}"
                 }
               }
        end

        should 'create a plate and increase the plate count' do
          assert_equal @plate_count + 1, Plate.count
        end
        should respond_with :ok
        should 'create a plate with the correct barcode' do
          assert_equal 'SQPD-1234567', Plate.last.barcodes.first.barcode
        end
      end

      context 'on POST to create both stock and RNA plates' do
        setup do
          @tube1 = FactoryBot.create(:tube)
          @tube2 = FactoryBot.create(:tube)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(
            build(:plate_barcode, barcode: 'SQPD-1234567'),
            build(:plate_barcode, barcode: 'SQPD-1234568')
          )

          # Initial plate count in the in-memory database
          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'All of the above',
                   source_tubes: "#{@tube1.barcodes.first}\r\n#{@tube2.barcodes.first}"
                 }
               }
        end
        should 'create a plate and increase the plate count' do
          assert_equal @plate_count + 2, Plate.count
        end
        should respond_with :ok
        should 'create a plate with the correct barcode' do
          assert_equal %w[SQPD-1234567 SQPD-1234568], Plate.all.map { |p| p.barcodes.first.barcode }.sort
        end
      end

      context 'on POST to create a stock plate and asset group' do
        setup do
          skip 'Skipping this test for now'
          @tube1 = FactoryBot.create(:sample_tube)
          @tube2 = FactoryBot.create(:sample_tube)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          Well.stubs(:studies).returns(@tube1.studies)

          # Initial plate count in the in-memory database
          @plate_count = Plate.count
          @asset_group_count = AssetGroup.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes: "#{@tube1.barcodes.first}\r\n#{@tube2.barcodes.first}",
                   create_asset_group: 'Yes'
                  }
                }
        end
        should 'create a plate and increase the plate count' do
          assert_equal @plate_count + 1, Plate.count
        end
        should 'create an asset group and increase the asset group count' do
          assert_equal @asset_group_count + 1, AssetGroup.count
        end
      end

      # Sad path
      context 'on POST to create a stock plate with too many tubes' do
        setup do
          source_tubes = (1..97).map { |_| FactoryBot.create(:tube).barcodes.first }.join("\r\n")
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes: source_tubes
                 }
               }
        end
        should 'not create a plate' do
          assert_equal 0, Plate.count
        end
        should set_flash[:error].to(/Number of tubes/)
      end
    end
  end
end
