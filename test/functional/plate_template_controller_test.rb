require "test_helper"
require 'assets_controller'

class PlateTemplatesControllerTest < ActionController::TestCase

  context "#PlateTemplates controller" do
    setup do
      @user = Factory(:slf_manager)
      @controller.stubs(:current_user).returns(@user)
    end
    should_require_login

    context "#index" do
      setup do
        get :index
      end
      should_render_template :index
      should_respond_with :success
      should_not_set_the_flash
    end

    context "#new" do
      setup do
        get :new
      end
      should_render_template :new
      should_respond_with :success
      should_not_set_the_flash
    end

    context "#create" do
      context "without parameters" do
        setup do
          post :create
        end
        should_respond_with :redirect
        should_set_the_flash_to "Please enter a name"
      end

      context "with valid parameters" do
        setup do
          @old_count_plate = PlateTemplate.count
          @old_count_wells = Well.count
          post :create, :name=>"test",:user_id=>@user.id, :rows => 8,  :cols => 12, :empty_well=>{"A1"=>1,"H12"=>96}
        end
        should_respond_with :redirect
        should_set_the_flash_to "Template saved"
        should "increment plate templates" do
          assert_equal @old_count_plate+1, PlateTemplate.count
        end
        should "increase wells by 2" do
          assert_equal @old_count_wells+2, Well.count
        end
      end
    end

    context "#update" do
      setup do
        @plate = PlateTemplate.new(:name => "test", :size=> 96)
        @plate.save
        @count_plate = PlateTemplate.count
        post :update, :name => "updated", :id => @plate.id, :user_id=>@user.id, :rows => 8,  :cols => 12
      end
      should "change name" do
        assert_equal "updated", PlateTemplate.find(@plate.id).name
      end
      should "not change number of plate templates" do
        assert_equal @count_plate,PlateTemplate.count
      end
    end
  end
end
