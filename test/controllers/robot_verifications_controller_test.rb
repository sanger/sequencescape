# frozen_string_literal: true

require 'test_helper'

class RobotVerificationsControllerTest < ActionController::TestCase
  context 'RobotVerificationsController' do
    setup do
      FactoryBot.create :plate_type, name: 'ABgene_0765', maximum_volume: 800
      @controller = RobotVerificationsController.new
      @request    = ActionController::TestRequest.create(@controller)
      @user = FactoryBot.create :user, barcode: 'ID41440E', swipecard_code: '1234567'
      @controller.stubs(:logged_in?).returns(@user)
      session[:user] = @user.id

      @batch = create :batch, barcode: '6262'
      @robot = create :robot, barcode: '1'
      @plate = create :plate, barcode: '142334'
      @destination_plate_scanned_barcode = @plate.machine_barcode
    end

    context '#index' do
      setup do
        get :index
      end

      should respond_with :success
    end

    context '#download' do
      setup do
        @expected_layout = [{ '142334' => 1 }, { '127168' => 3, '134443' => 4, '127162' => 1, '127167' => 2 }]
        @expected_layout[0].each do |_barcode, bed_number|
          @robot.robot_properties.create(key: "DEST#{bed_number}", value: '5')
        end

        @expected_layout[1].each_with_index do |(barcode, bed_number), index|
          @robot.robot_properties.create(key: "SCRC#{bed_number}", value: bed_number)
          source_plate = create :plate, barcode: barcode
          position = Map.for_position_on_plate(index + 1, 96, source_plate.asset_shape).first

          well = create :well, map: position, plate: source_plate

          target_well = create :well, map: position, plate: @plate
          well_request = create :request, state: 'passed', asset: well, target_asset: target_well
          @batch.requests << well_request
        end
        @robot.save
        @before_event_count = Event.count
      end

      context 'with valid inputs' do
        setup do
          post :download, params: { user_id: @user.id,
                                    batch_id: @batch.id,
                                    robot_id: @robot.id,
                                    source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                    barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                    bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                    plate_barcodes: { 'DN127162U' => 'DN127162U', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                    destination_bed_barcodes: { '1' => '580000005842' },
                                    destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
        end

        should 'be successful' do
          assert_response :success
          assert_equal @before_event_count + 1, Event.count
        end
      end
      context 'with invalid inputs' do
        context 'where nothing is scanned' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '', '2' => '', '3' => '', '4' => '' },
                                      plate_barcodes: { 'DN127162U' => '', 'DN127167C' => '', 'DN127168D' => '', 'DN134443T' => '' },
                                      destination_bed_barcodes: { '1' => '' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => '' } }
          end

          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end

        context 'where the source plates are missing' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => '', 'DN127167C' => '', 'DN127168D' => '', 'DN134443T' => '' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end

        context 'where the source beds are missing' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '', '2' => '', '3' => '', '4' => '' },
                                      plate_barcodes: { 'DN127162U' => 'DN127162U', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'there the source plates are mixed up' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127167C' => 'DN127162U', 'DN127162U' => 'DN127167C', 'DN134443T' => 'DN127168D', 'DN127168D' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the source beds are mixed up' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '4' => '580000001806', '3' => '580000002810', '1' => '580000003824', '2' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => 'DN127162U', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where 2 source beds and plates are mixed up' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => 'DN127162U', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => '580000001806', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the destination plate is missing' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => 'DN127162U', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => '' } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the destination bed is missing' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => 'DN127162U', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the source and destination plates are mixed up' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: 'ABgene_0765',
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => 'DN127162U', 'DN127167C' => 'DN127167C', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => @destination_plate_scanned_barcode },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => '580000005842' } }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where there are spaces in the input barcodes' do
          setup do
            post :download, params: { user_id: @user.id,
                                      batch_id: @batch.id,
                                      robot_id: @robot.id,
                                      source_plate_types: { 'DN127162U' => 'ABgene_0765', 'DN127167C' => 'ABgene_0765', 'DN127168D' => 'ABgene_0765', 'DN134443T' => 'ABgene_0765' },
                                      barcodes: { destination_plate_barcode: @destination_plate_scanned_barcode },
                                      bed_barcodes: { '1' => ' 580000001806', '2' => '580000002810    ', '3' => '  580000003824', '4' => '580000004838' },
                                      plate_barcodes: { 'DN127162U' => 'DN127162U     ', 'DN127167C' => 'DN127167C ', 'DN127168D' => 'DN127168D', 'DN134443T' => 'DN134443T' },
                                      destination_bed_barcodes: { '1' => '580000005842' },
                                      destination_plate_barcodes: { @destination_plate_scanned_barcode => @destination_plate_scanned_barcode } }
          end
          should 'be successful' do
            assert_response :success
            assert_equal @before_event_count + 1, Event.count
          end
        end
      end
    end

    context '#submission' do
      setup do
        @well = FactoryBot.create :well, plate: @plate
        @well_request = FactoryBot.create :request, state: 'passed'
        @source_plate = FactoryBot.create :plate, barcode: '1234'
        @target_well = FactoryBot.create :well, plate: @source_plate
        @well_request.asset = @well
        @well_request.target_asset = @target_well
        @well_request.save
        @batch.requests << @well_request
      end
      context 'with valid inputs' do
        setup do
          post :submission, params: { barcodes: { batch_barcode: '550006262686',
                                                  robot_barcode: '4880000001780',
                                                  destination_plate_barcode: @destination_plate_scanned_barcode,
                                                  user_barcode: '1234567' } }
        end
        should 'be successful' do
          assert_response :success
        end
      end
      context 'with invalid batch' do
        setup do
          post :submission, params: { barcodes: { batch_barcode: '1111111111111',
                                                  robot_barcode: '4880000001780',
                                                  destination_plate_barcode: @destination_plate_scanned_barcode,
                                                  user_barcode: '2470041440697' } }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
      context 'with invalid robot' do
        setup do
          post :submission, params: { barcodes: { batch_barcode: '550006262686',
                                                  robot_barcode: '111111111111',
                                                  destination_plate_barcode: @destination_plate_scanned_barcode,
                                                  user_barcode: '2470041440697' } }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
      context 'with invalid destination plate' do
        setup do
          post :submission, params: { barcodes: { batch_barcode: '550006262686',
                                                  robot_barcode: '4880000001780',
                                                  destination_plate_barcode: '111111111111',
                                                  user_barcode: '2470041440697' } }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
      context 'with invalid user' do
        setup do
          post :submission, params: { barcodes: { batch_barcode: '550006262686',
                                                  robot_barcode: '4880000001780',
                                                  destination_plate_barcode: @destination_plate_scanned_barcode,
                                                  user_barcode: '1111111111111' } }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
    end
  end
end
