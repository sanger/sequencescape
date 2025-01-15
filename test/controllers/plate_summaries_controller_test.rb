# frozen_string_literal: true

require 'test_helper'
require 'projects_controller'

class PlateSummariesControllerTest < ActionController::TestCase
  context 'PlateSummariesController' do
    setup do
      @controller = PlateSummariesController.new
      @request = ActionController::TestRequest.create(@controller)
      @user = create(:user)
      session[:user] = @user.id
    end

    context 'with some plates' do
      setup do
        purpose = create(:source_plate_purpose)
        @source_plate_a = create(:source_plate, purpose:)
        @source_plate_b = create(:source_plate, purpose:)
        @child_plate_a = create(:child_plate, parent: @source_plate_a)
        @child_plate_b = create(:child_plate, parent: @source_plate_b)
      end

      should 'test factory is created' do
        assert @source_plate_a
      end

      context '#index' do
        setup { create(:plate_owner, user: @user, plate: @child_plate_a) }

        should 'include owned plates' do
          get :index
          assert_response :success
          assert_includes assigns(:plates), @source_plate_a
        end
      end

      context '#search' do
        should 'find expected plates' do
          plates = {
            @source_plate_a => [
              @source_plate_a.human_barcode,
              @source_plate_a.machine_barcode,
              @child_plate_a.human_barcode,
              @child_plate_a.machine_barcode
            ],
            @source_plate_b => [
              @source_plate_b.human_barcode,
              @source_plate_b.machine_barcode,
              @child_plate_b.human_barcode,
              @child_plate_b.machine_barcode
            ]
          }
          plates.each do |plate, barcodes|
            barcodes.each do |barcode|
              get :search, params: { plate_barcode: barcode }
              assert_redirected_to plate_summary_path(plate.human_barcode)
            end
          end
        end

        context 'return users to search page if barcode not found' do
          setup do
            @request.env['HTTP_REFERER'] = 'back'
            get :search, params: { plate_barcode: 'abcd' }
          end

          should redirect_to('/')
          should set_flash.to 'No suitable plates found for barcode abcd'
        end

        context 'render the search page with a list of plates if multiple found' do
          setup do
            @child_plate_a.parents << @source_plate_b
            get :search, params: { plate_barcode: @child_plate_a.human_barcode }
          end

          should render_template 'search'

          should 'list the possible plates' do
            assert_includes assigns(:plates), @source_plate_a
            assert_includes assigns(:plates), @source_plate_b
          end
        end
      end

      context '#show' do
        setup { @collection = create(:custom_metadatum_collection_with_metadata, asset: @child_plate_a, user: @user) }

        should 'return expected plate' do
          get :show, params: { id: @source_plate_a.human_barcode }
          assert_response :success
          assert_equal @source_plate_a, assigns(:plate)
        end

        should 'show the metadata for the plate' do
          get :show, params: { id: @child_plate_a.human_barcode }
          assert_response :success
          assert_equal @collection.metadata.count, assigns(:plate).metadata.count
        end
      end
    end
  end
end
