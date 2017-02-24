# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class PicoDilutionsControllerTest < ActionController::TestCase
  context 'Pico Dilution Plate' do
    setup do
      @controller = PicoDilutionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    context 'with assay plates ' do
      setup do
        @pico_dilution_plate = FactoryGirl.create :pico_dilution_plate, barcode: '2222'
        @assay_plate_a = FactoryGirl.create :pico_assay_a_plate, barcode: '9999'
        @assay_plate_b = FactoryGirl.create :pico_assay_b_plate, barcode: '8888'
        AssetLink.create_edge!(@pico_dilution_plate, @assay_plate_a)
        AssetLink.create_edge!(@pico_dilution_plate, @assay_plate_b)
      end

      context '#index' do
        setup do
          @request.accept = 'application/json'
        end

        context 'no page passed in ' do
          setup do
            get :index
          end
          should respond_with :success
          should 'Respond with json' do
            assert_equal 'application/json', @response.content_type
          end

          should 'find the pico dilution plate' do
            assert @response.body.include?(@pico_dilution_plate.ean13_barcode)
            assert @response.body.include?(@assay_plate_a.ean13_barcode)
            assert @response.body.include?(@assay_plate_b.ean13_barcode)
            assert_equal 1, JSON.parse(@response.body).count
          end
        end
        context 'page passed in' do
          setup do
            get :index, page: 3
          end
          should respond_with :success
          should 'Respond with json' do
            assert_equal 'application/json', @response.content_type
          end
        end
      end
    end
  end

  context 'Working Dilution Plate' do
    setup do
      @controller = PicoDilutionsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    context 'with assay plates ' do
      setup do
        @working_dilution_plate_a = create :working_dilution_plate, barcode: '2222'
        @working_dilution_plate_b = create :working_dilution_plate, barcode: '2223'
        @assay_plate_a = create :pico_assay_a_plate, barcode: '9999'
        @assay_plate_b = create :pico_assay_b_plate, barcode: '8888'
        @assay_plate_c = create :pico_assay_a_plate, barcode: '5555'
        @assay_plate_d = create :pico_assay_a_plate, barcode: '5555'
        @sequenom_plate_a = create :sequenom_qc_plate, barcode: '7777', name: 'a'
        @sequenom_plate_b = create :sequenom_qc_plate, barcode: '6666', name: 'b'

        AssetLink.create_edge!(@working_dilution_plate_a, @assay_plate_a)
        AssetLink.create_edge!(@working_dilution_plate_a, @assay_plate_b)
        AssetLink.create_edge!(@working_dilution_plate_a, @sequenom_plate_a)
        AssetLink.create_edge!(@working_dilution_plate_b, @sequenom_plate_b)
        AssetLink.create_edge!(@sequenom_plate_b, @assay_plate_c) # Ignore indirect links
        AssetLink.create_edge!(@assay_plate_a, @assay_plate_d) # Ignore indirect children
      end

      context '#index' do
        setup do
          @request.accept = 'application/json'
        end

        context 'no page passed in ' do
          setup do
            get :index
          end

          should 'should find the working dilution with pico children' do
            assert @response.body.include?(@working_dilution_plate_a.ean13_barcode), "Couldn't find Working Dilution Plate"
            assert @response.body.include?(@assay_plate_a.ean13_barcode), "Couldn't find PicoA child"
            assert @response.body.include?(@assay_plate_b.ean13_barcode), "Couldn't find PicoB Child"
            assert_equal 1, JSON.parse(@response.body).count
          end

          should "should not find plates we don't want" do
            assert !@response.body.include?(@working_dilution_plate_b.ean13_barcode), 'Found Working Dilution without Pico Children'
            assert !@response.body.include?(@sequenom_plate_a.ean13_barcode), 'Found non pico child of working dilution'
            assert !@response.body.include?(@assay_plate_d.ean13_barcode), 'Found indirect pico child of working dilution'
          end
        end
      end
    end
  end
end
