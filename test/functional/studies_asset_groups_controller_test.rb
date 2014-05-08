require "test_helper"

# Re-raise errors caught by the controller.
class Studies::AssetGroupsController; def rescue_action(e) raise e end; end

class Studies::AssetGroupsControllerTest < ActionController::TestCase

  def self.view_page_with_no_updates
    should_respond_with :success
    should_change("AssetGroup.count", :by => 0) { AssetGroup.count }
    should_change("Study.count", :by => 0) { Study.count }
  end

  context "Studies AssetGroups" do
    setup do
      @controller = Studies::AssetGroupsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :user
      @controller.stubs(:current_user).returns(@user)
      @controller.stubs(:logged_in?).returns(@user)
      @study = Factory :study
      @asset_group = Factory :asset_group
    end

    should_require_login

    ["index","new"].each do |controller_method|
      context "##{controller_method}" do
        setup do
          get controller_method, :study_id => @study.id
        end
        view_page_with_no_updates
      end
    end

    ["show", "edit", "print", "printing"].each do |controller_method|
      context "##{controller_method}" do
        setup do
          get controller_method, :study_id => @study.id, :id => @asset_group.id
        end
        view_page_with_no_updates
      end
    end

    context "#search" do
      context "should redirect if no query is passed in" do
        setup do
          get :search, :study_id => @study.id, :id => @asset_group.id
        end

        should_respond_with :redirect
      end

      context "should redirect if it is given a blank query" do
        setup do
          get :search, :study_id => @study.id, :id => @asset_group.id, :q => ""
        end

        should_respond_with :redirect
      end

      context "should redirect if too small a query is passed" do
        setup do
          get :search, :study_id => @study.id, :id => @asset_group.id, :q => "a"
        end

        should_respond_with :redirect
      end

      context "should suceed with a query longer than 1" do
        setup do
          get :search, :study_id => @study.id, :id => @asset_group.id, :q => "ab"
        end

        should_respond_with :success
      end
    end

    context "#destroy" do
      setup do
        delete :destroy, :study_id => @study.id, :id => @asset_group.id
      end
      should_change("AssetGroup.count", :by => -1) { AssetGroup.count }
      should_change("Study.count", :by => 0) { Study.count }
      should_respond_with :redirect
    end

    context "#update" do
      setup do
        put :update, :study_id => @study.id, :id => @asset_group.id, :name=>"update name"
      end
      should_set_the_flash_to /updated/
      should_change("AssetGroup.count", :by => 0) { AssetGroup.count }
      should_change("Study.count", :by => 0) { Study.count }
      should_respond_with :redirect
      should "set name" do
        assert "update name", AssetGroup.find(@asset_group.id).name
      end
    end

  end
end
