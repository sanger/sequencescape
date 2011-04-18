require "test_helper"
require 'samples_controller'

# Re-raise errors caught by the controller.
class SamplesController; def rescue_action(e) raise e end; end

class SamplesControllerTest < ActionController::TestCase
  context "Samples controller" do
    setup do
      @controller = SamplesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      Sample.stubs(:assets).returns([])
    end
    
    should_require_login
    
    # NOTE: You can update a sample through this controller, you just can't change the name, which is 
    # why, if you remove 'update' from the 'ignore_actions' you'll find the test fails!
    resource_test(
      'sample', {
        :defaults => {:name => "Sample22"}, 
        :formats => ['html'], 
        :ignore_actions =>['show','create','update'], 
        :user => lambda { user = Factory(:user) ; user.is_administrator ; user }
      }
    )

    # TODO: Test without admin
    context "when logged in" do
      setup do
        @user = Factory :user
        @controller.stubs(:logged_in?).returns(@user)
        @controller.stubs(:current_user).returns(@user)
      end
      
      context "#add_to_study" do
        setup do
          @sample = Factory :sample
          @study = Factory :study
          put :add_to_study, :id => @sample.id, :study => { :id => @study.id }
        end
        should_change("StudySample.count", :from => 0, :to => 1) { StudySample.count }
        should_redirect_to("sample path") { sample_path(@sample) }
      end

      context "#automatic move sample" do
        setup do
          @study_from = Factory :study, :id => "69" 
          @study_to = Factory :study, :id => "96"
        end
        
        should "without correct data give Error." do
          post :move_upload, :file => File.open(RAILS_ROOT + '/test/data/upload_sample_move.xls')
          assert_equal "Caution, errors were found. Lines with errors are not processed.", flash[:error]
        end

        should "with correct data all sample in XLS are moved." do
          @sample = Factory :sample, :id => 696969
          @workflow = Factory :submission_workflow
          @study_sample = Factory :study_sample, :study => @study_from, :sample => @sample
          post :move_upload, :file => File.open(RAILS_ROOT + '/test/data/upload_sample_move.xls')
          
          assert_equal nil, flash[:error]
        end

      end

      context "#move" do
        context "if study_to or study_from is not selected" do
          setup do
            @sample2 = Factory :sample
          end
          should "redirect and move fails with error" do
            post :move, :id => @sample2.id, :study_id_from => 0, :study_id_to => 0
            assert_equal "You have to select 'Study From' and 'Study To'", flash[:error]
            assert_response :redirect
          end
        end

        context "if asset is not selected" do
          setup do
            @sample2 = Factory :sample
            @study_from = Factory :study
            @study_to = Factory :study
            @new_assets_name = ""
          end
          should "redirect and move fails with error" do
            post :move, :id => @sample2.id, :study_id_from => @study_from.id, :study_id_to => @study_to.id, :asset_group_id => 0, :new_assets_name => @new_assets_name
            assert_equal "You must indicate an 'Asset Group'.", flash[:error]
            assert_response :redirect
          end
        end

        context "if exists a submission and it is not selected" do
          setup do
            @sample_from = Factory :sample
            @study_from = Factory :study
            @study_to = Factory :study
            @new_assets_name = ""

            @asset_to = Factory :asset
            @asset_group_to = Factory :asset_group, :study_id => @study_to.id
            @asset_group_asset_to = Factory :asset_group_asset, :asset_id =>  @asset_to.id , :asset_group_id => @asset_group_to.id
            @submission_to = Factory :submission, :study_id => @study_to.id, :assets => [ @asset_to ]
          end

          should "redirect and move fails with error" do
            post :move, :id => @sample_from.id, :study_id_from => @study_from.id, :study_id_to => @study_to.id, :asset_group_id => @asset_group_to.id , :new_assets_name => @new_assets_name, :submission_id => 0
            assert_equal "You must select a Submission because you select an Asset with Submissions.", flash[:error]
            assert_response :redirect
          end
        end
      end
    end
  end 
end
