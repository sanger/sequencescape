# frozen_string_literal: true

require 'test_helper'
class PlatesFromTubesControllerTest < ActionController::TestCase
  context 'Plates from Tubes' do
    setup do
      @controller = PlatesFromTubesController.new
      @request = ActionController::TestRequest.create(@controller)

      # Populating plate purposes
      @stock_plate_purpose = create(:plate_purpose, name: 'Stock Plate')
      @rna_stock_plate_purpose = create(:plate_purpose, name: 'Stock RNA Plate')

      # Populating plate creators
      @stock_plate_creator = create(:plate_creator, name: 'Stock Plate', plate_purposes: [@stock_plate_purpose])
      @rna_stock_plate_creator =
        create(:plate_creator, name: 'Stock RNA Plate', plate_purposes: [@rna_stock_plate_purpose])

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
          @tube1 = FactoryBot.create(:sample_tube)
          @tube2 = FactoryBot.create(:sample_tube)

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
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode,
                     A2: @tube2.barcodes.first.barcode
                   }.to_json
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
        should 'create put the tubes in the correct positions on the new plate' do
          # Well A1
          assert_equal @tube1.samples.first, Plate.last.wells.first.samples.first
          # Well A2
          assert_equal @tube2.samples.first, Plate.last.wells.second.samples.first
        end
      end

      context 'on POST to create a stock plate with blank wells' do
        setup do
          @tube1 = FactoryBot.create(:sample_tube)
          @tube2 = FactoryBot.create(:sample_tube)

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
                   source_tubes_map: {
                     A4: @tube1.barcodes.first.barcode,
                     A6: @tube2.barcodes.first.barcode
                   }.to_json
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
        should 'create put the tubes in the correct positions on the new plate' do
          # Well A4
          assert_equal @tube1.samples.first, Plate.last.wells[3].samples.first
          # Well A6
          assert_equal @tube2.samples.first, Plate.last.wells[5].samples.first
        end
      end

      context 'on POST to create the asset links (as well as the plate)' do
        setup do
          @tube1 = FactoryBot.create(:sample_tube)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          # Initial asset link count in the in-memory database
          @asset_links = AssetLink.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode
                   }.to_json
                 }
               }
        end

        should 'increase the asset link count by 1' do
          assert_equal @asset_links + 1, AssetLink.count
        end

        should 'create the correct asset_link ancestor' do
          assert_equal AssetLink.last.ancestor_id, Tube.last.id
        end

        should 'create the correct asset_link descendant' do
          assert_equal AssetLink.last.descendant_id, Plate.last.id
        end
      end

      context 'on POST to create an RNA plate' do
        setup do
          @tube1 = FactoryBot.create(:sample_tube)
          @tube2 = FactoryBot.create(:sample_tube)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          # Initial plate count in the in-memory database
          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock RNA Plate',
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode,
                     A2: @tube2.barcodes.first.barcode
                   }.to_json
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
          @tube1 = FactoryBot.create(:sample_tube)
          @tube2 = FactoryBot.create(:sample_tube)

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
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode,
                     A2: @tube2.barcodes.first.barcode
                   }.to_json
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
          @sample1 = FactoryBot.create(:sample)
          @sample2 = FactoryBot.create(:sample)
          @tube1 = FactoryBot.create(:sample_tube, sample: @sample1)
          @tube2 = FactoryBot.create(:sample_tube, sample: @sample2)

          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          # Initial plate count in the in-memory database
          @plate_count = Plate.count
          @asset_group_count = AssetGroup.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode,
                     A2: @tube2.barcodes.first.barcode
                   }.to_json,
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

      context 'on POST with duplicate barcodes' do
        setup do
          @tube1 = FactoryBot.create(:sample_tube)
          @tube2 = FactoryBot.create(:sample_tube)

          @plate_count = Plate.count

          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode,
                     A2: @tube1.barcodes.first.barcode,
                     A3: @tube2.barcodes.first.barcode
                   }.to_json
                 }
               }
        end

        should 'not create a plate' do
          assert_equal @plate_count, Plate.count
        end

        should set_flash[:error].to(/Duplicate tubes found/)
      end

      context 'on POST to create a stock plate with a tube with invalid positions' do
        setup do
          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          source_tubes = (1..3).map { |_| FactoryBot.create(:sample_tube).barcodes.first.barcode }

          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {
                     A13: source_tubes[0],
                     H0: source_tubes[1],
                     J1: source_tubes[2]
                   }.to_json
                 }
               }
        end

        should 'not create a plate' do
          assert_equal 0, Plate.count
        end

        should set_flash[:error].to(/Plate creation failed: Tube position A13 is not valid/)
      end

      context 'on POST to create a stock plate with missing tubes' do
        setup do
          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {
                     A1: 'SHRODINGERS_TUBE_BARCODE'
                   }.to_json
                 }
               }
        end

        should 'not create a plate' do
          assert_equal @plate_count, Plate.count
        end
        should set_flash[:error].to(/Tube with barcode SHRODINGERS_TUBE_BARCODE not found/)
      end

      context 'on POST to create a stock plate with no tubes' do
        setup do
          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {}.to_json
                 }
               }
        end

        should 'not create a plate' do
          assert_equal @plate_count, Plate.count
        end
        should set_flash[:error].to(/No tubes to transfer/)
      end

      context 'on POST to create a stock plate with bad json' do
        setup do
          # Stubbing the barcode generation call for the new plate generated
          PlateBarcode.stubs(:create_barcode).returns(build(:plate_barcode, barcode: 'SQPD-1234567'))

          @plate_count = Plate.count
          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: '{bad json : }}'
                 }
               }
        end

        should 'not create a plate' do
          assert_equal @plate_count, Plate.count
        end

        should set_flash[:error].to(
          "Source tubes input is not valid JSON. Error message: expected object key, got 'bad' at line 1 column 2"
        )
      end

      context 'without a user barcode' do
        setup do
          @user = FactoryBot.create(:user, swipecard_code: '1234567')
          @user.grant_administrator
          session[:user] = @user.id
        end

        context 'on POST to create a plate' do
          setup do
            @tube1 = FactoryBot.create(:sample_tube)
            @tube2 = FactoryBot.create(:sample_tube)

            # Initial plate count in the in-memory database
            @plate_count = Plate.count
            post :create,
                 params: {
                   plates_from_tubes: {
                     user_barcode: nil,
                     barcode_printer: @barcode_printer.id,
                     plate_type: 'Stock Plate',
                     source_tubes_map: {
                       A1: @tube1.barcodes.first.barcode,
                       A2: @tube2.barcodes.first.barcode
                     }.to_json
                   }
                 }
          end

          should 'not create a plate and increase the plate count' do
            assert_equal @plate_count, Plate.count
          end
          should set_flash[:error].to(/Please enter a valid user barcode/)
        end
      end

      context 'on POST to create a stock plate with empty tubes' do
        setup do
          @tube1 = FactoryBot.create(:tube)
          @tube2 = FactoryBot.create(:sample_tube)

          @plate_count = Plate.count

          post :create,
               params: {
                 plates_from_tubes: {
                   user_barcode: '1234567',
                   barcode_printer: @barcode_printer.id,
                   plate_type: 'Stock Plate',
                   source_tubes_map: {
                     A1: @tube1.barcodes.first.barcode,
                     A2: @tube2.barcodes.first.barcode
                   }.to_json
                 }
               }
        end

        should 'not create a plate' do
          assert_equal 0, Plate.count
        end
        should set_flash[:error].to(/No samples were found in the following tubes:/)
      end
    end
  end
end
