require 'test_helper'

class GetYourQcCompletedTubesHereControllerTest < ActionController::TestCase
  context 'Get Your Qc Completed Tubes Here Controller' do
    attr_reader :user

    setup do
      @controller = GetYourQcCompletedTubesHereController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user       = create(:user)
      @controller.stubs(:current_user).returns(@user)
      @controller.stubs(:logged_in?).returns(@user)
    end

    context '#create' do
      attr_reader :plate, :study, :generator

      setup do
        @study = create(:study)
        @plate = create(:plate)
        @generator = LibPoolNormTubeGenerator.new(plate.ean13_barcode, user, study)
        generator.stubs(:valid?).returns(true)
        generator.stubs(:create!).returns(true)
        generator.stubs(:asset_group).returns(AssetGroup.create(assets: create_list(:lib_pcr_xp_tube, 3), study: create(:study), name: 'Asset Group 1'))
      end

      should 'create some assets, redirect to the asset group' do
        LibPoolNormTubeGenerator.stubs(:new).returns(generator)
        post :create, barcode: plate.ean13_barcode, study: study.id
        assert_equal 3, assigns(:generator).asset_group.assets.length
        assert_redirected_to study_asset_groups_path(assigns(:generator).study.id)
        assert_match "QC Completed tubes successfully created for #{plate.sanger_human_barcode}. Go celebrate!", flash[:notice]
      end

      should 'return an error message if it fails for some reason' do
        generator.stubs(:create!).returns(false)
        LibPoolNormTubeGenerator.stubs(:new).returns(generator)
        post :create, barcode: plate.ean13_barcode, study: study.id
        assert_match "Oh dear, your tubes weren't created. It's not you its me so please contact PSD.", flash[:error]
      end
    end

    context 'no plate' do
      should 'return an error if the plate does not exist' do
        post :create, barcode: 'No plate here, move on!'
        assert_match 'Barcode does not relate to any existing plate', flash[:error]
      end
    end
  end
end
