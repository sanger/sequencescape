require "test_helper"

# Re-raise errors caught by the controller.
class SearchesController; def rescue_action(e) raise e end; end

class SearchesControllerTest < ActionController::TestCase
  context "Searches controller" do
    setup do
      @controller = SearchesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context "searching (when logged in)" do
      setup do
        @user = Factory :user
        @controller.stubs(:logged_in?).returns(@user)
        @controller.stubs(:current_user).returns(@user)

        @study                    = Factory :study, :name => "FindMeStudy"
        @study2                   = Factory :study, :name => "Another study"
        @sample                   = Factory :sample, :name => "FindMeSample"
        @asset                    = Factory(:sample_tube, :name => 'FindMeAsset')
        @asset_group_to_find      = Factory :asset_group, :name => "FindMeAssetGroup", :study => @study
        @asset_group_to_not_find  = Factory :asset_group, :name => "IgnoreAssetGroup"

      end
      context "#index" do
        setup do
          get :index, :q => "FindMe"
        end

        should_respond_with :success

        context "results" do
          define_method(:assert_link_to) do |url|
            assert_tag :tag => 'a', :attributes => { :href => url }
          end

          define_method(:deny_link_to) do |url|
            assert_no_tag :tag => 'a', :attributes => { :href => url }
          end

          should "contain a link to the study that was found" do
            assert_link_to study_path(@study)
          end

          should "not contain a link to the study that was not found" do
            deny_link_to study_path(@study2)
          end

          should "contain a link to the sample that was found" do
            assert_link_to sample_path(@sample)
          end

          should 'contain a link to the asset that was found' do
            assert_link_to asset_path(@asset)
          end

          should "contain a link to the asset_group that was found" do
            assert_link_to study_asset_group_path(@asset_group_to_find.study, @asset_group_to_find)
          end
        end
      end
    end
  end
end
