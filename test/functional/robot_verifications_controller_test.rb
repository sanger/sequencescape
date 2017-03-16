# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

require 'test_helper'

class RobotVerificationsControllerTest < ActionController::TestCase
  context 'RobotVerificationsController' do
    setup do
      @controller = RobotVerificationsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = FactoryGirl.create :user, barcode: 'ID41440E'
      @controller.stubs(:logged_in?).returns(@user)
      session[:user] = @user.id

      @batch = FactoryGirl.create :batch, barcode: '6262'
      @robot = FactoryGirl.create :robot, barcode: '1'
      @plate = FactoryGirl.create :plate, barcode: '142334'
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
        count = 1;
        @expected_layout[1].each do |barcode, bed_number|
          @robot.robot_properties.create(key: "SCRC#{bed_number}", value: bed_number)
          @source_plate = FactoryGirl.create :plate, barcode: barcode
          well = FactoryGirl.create :well, map_id: Map.for_position_on_plate(count, 96, @source_plate.asset_shape).first.id
          target_well = FactoryGirl.create :well, map_id: Map.for_position_on_plate(count, 96, @source_plate.asset_shape).first.id
          target_well.well_attribute = FactoryGirl.create :well_attribute
          @source_plate.add_and_save_well(well)
          @plate.add_and_save_well(target_well)
          well_request = FactoryGirl.create :request, state: 'passed'
          well_request.asset = well
          well_request.target_asset = target_well
          well_request.save
          @batch.requests << well_request
          count = 1 + count
        end
        @robot.save
        @before_event_count = Event.count
      end

      context 'with valid inputs' do
        setup do
          post :download,   user_id: @user.id,
                            batch_id: @batch.id,
                            robot_id: @robot.id,
                            source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                            barcodes: { destination_plate_barcode: '1220142334774' },
                            bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                            plate_barcodes: { '1220127162859' => '1220127162859', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                            destination_bed_barcodes: { '1' => '580000005842' },
                            destination_plate_barcodes: { '1220142334774' => '1220142334774' }
        end

        should 'be successful' do
          assert_response :success
          assert_equal @before_event_count + 1, Event.count
        end
      end
      context 'with invalid inputs' do
        context 'where nothing is scanned' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '', '2' => '', '3' => '', '4' => '' },
                              plate_barcodes: { '1220127162859' => '', '1220127167670' => '', '1220127168684' => '', '1220134443842' => '' },
                              destination_bed_barcodes: { '1' => '' },
                              destination_plate_barcodes: { '1220142334774' => '' }
          end

          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end

        context 'where the source plates are missing' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '', '1220127167670' => '', '1220127168684' => '', '1220134443842' => '' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end

        context 'where the source beds are missing' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '', '2' => '', '3' => '', '4' => '' },
                              plate_barcodes: { '1220127162859' => '1220127162859', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'there the source plates are mixed up' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127167670' => '1220127162859', '1220127162859' => '1220127167670', '1220134443842' => '1220127168684', '1220127168684' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the source beds are mixed up' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '4' => '580000001806', '3' => '580000002810', '1' => '580000003824', '2' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '1220127162859', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where 2 source beds and plates are mixed up' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '1220127162859', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '580000001806', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the destination plate is missing' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '1220127162859', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the destination bed is missing' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '1220127162859', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where the source and destination plates are mixed up' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: 'ABgene_0765',
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => '580000001806', '2' => '580000002810', '3' => '580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '1220127162859', '1220127167670' => '1220127167670', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '1220142334774' },
                              destination_plate_barcodes: { '1220142334774' => '580000005842' }
          end
          should 'redirect and set the flash to error' do
            assert_response :redirect
            assert_not_nil flash[:error].include?('Error')
            assert_equal @before_event_count + 1, Event.count
          end
        end
        context 'where there are spaces in the input barcodes' do
          setup do
            post :download,   user_id: @user.id,
                              batch_id: @batch.id,
                              robot_id: @robot.id,
                              source_plate_types: { '1220127162859' => 'ABgene_0765', '1220127167670' => 'ABgene_0765', '1220127168684' => 'ABgene_0765', '1220134443842' => 'ABgene_0765' },
                              barcodes: { destination_plate_barcode: '1220142334774' },
                              bed_barcodes: { '1' => ' 580000001806', '2' => '580000002810    ', '3' => '  580000003824', '4' => '580000004838' },
                              plate_barcodes: { '1220127162859' => '1220127162859     ', '1220127167670' => '1220127167670 ', '1220127168684' => '1220127168684', '1220134443842' => '1220134443842' },
                              destination_bed_barcodes: { '1' => '580000005842' },
                              destination_plate_barcodes: { '1220142334774' => '1220142334774' }
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
        @well = FactoryGirl.create :well
        @well_request = FactoryGirl.create :request, state: 'passed'

        @target_well = FactoryGirl.create :well
        @plate.add_and_save_well(@well)
        @source_plate = FactoryGirl.create :plate, barcode: '1234'
        @source_plate.add_and_save_well(@target_well)
        @well_request.asset = @well
        @well_request.target_asset = @target_well
        @well_request.save
        @batch.requests << @well_request
      end
      context 'with valid inputs' do
        setup do
          post :submission, barcodes: { batch_barcode: '550006262686',
                                        robot_barcode: '4880000001780',
                                        destination_plate_barcode: '1220142334774',
                                        user_barcode: '2470041440697' }
        end
        should 'be successful' do
          assert_response :success
        end
      end
      context 'with invalid batch' do
        setup do
          post :submission, barcodes: { batch_barcode: '1111111111111',
                                        robot_barcode: '4880000001780',
                                        destination_plate_barcode: '1220142334774',
                                        user_barcode: '2470041440697' }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
      context 'with invalid robot' do
        setup do
          post :submission, barcodes: { batch_barcode: '550006262686',
                                        robot_barcode: '111111111111',
                                        destination_plate_barcode: '1220142334774',
                                        user_barcode: '2470041440697' }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
      context 'with invalid destination plate' do
        setup do
          post :submission, barcodes: { batch_barcode: '550006262686',
                                        robot_barcode: '4880000001780',
                                        destination_plate_barcode: '111111111111',
                                        user_barcode: '2470041440697' }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
      context 'with invalid user' do
        setup do
          post :submission, barcodes: { batch_barcode: '550006262686',
                                        robot_barcode: '4880000001780',
                                        destination_plate_barcode: '1220142334774',
                                        user_barcode: '1111111111111' }
        end
        should 'redirect and set the flash to error' do
          assert_response :redirect
          assert_not_nil flash[:error].include?('Invalid')
        end
      end
    end
  end
end
