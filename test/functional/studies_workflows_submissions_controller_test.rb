require "test_helper"

# Re-raise errors caught by the controller.
class Studies::Workflows::SubmissionsController; def rescue_action(e) raise e end; end

class Studies::Workflows::SubmissionsControllerTest < ActionController::TestCase
  context "Studies::Workflows::SubmissionsController" do
    setup do
      @controller  = Studies::Workflows::SubmissionsController.new
      @request     = ActionController::TestRequest.new
      @response    = ActionController::TestResponse.new
    end

    should_require_login

    context "#index" do
      context "when not logged in" do
        setup do
          get :index
        end

        should_redirect_to("login page") { login_path }
      end

      context "when logged in" do
        setup do
          @user = Factory :user
          @workflow = Factory :submission_workflow
          @study  = Factory :study
          @controller.stubs(:logged_in?).returns(@user)
          @controller.stubs(:current_user).returns(@user)
          get :index, :workflow_id => @workflow.id, :study_id => @study.id
        end

        should_respond_with :success
        should_render_template :index

        should "display a list of all submission" do
          @submissions = Submission.count
          assert_not_nil @submissions
        end
      end
    end

    context "#new" do
      context "when not logged in" do
        setup do
          get :new
        end

        should_redirect_to("login page") { login_path }
      end

      context "when logged in" do
        setup do
          @user = Factory :owner
          @controller.stubs(:logged_in?).returns(@user)
          @controller.stubs(:current_user).returns(@user)
        end

        context "when no params are passed" do
          should "raise an AR error" do
            assert_raise ActiveRecord::RecordNotFound do
              get :new
            end
          end
        end

        context "when params are passed" do
          setup do
            @study = Factory :study
            @study.study_metadata.study_ebi_accession_number = 'Test'
            @study.study_metadata.data_release_strategy = 'managed'
            @study.study_metadata.study_type = StudyType.find_by_name("Not specified")
            @study.study_metadata.data_release_study_type = DataReleaseStudyType.find_by_name('genomic sequencing') 
            

            @workflow = Factory :submission_workflow
            @submission_template = Factory :submission_template

            $stop = true
            get :new, :study_id => @study.id, :workflow_id => @workflow.id, :submission_template_id => @submission_template.id
            $stop = false
          end

          should "respond successfully and render the new template" do
            assert_response :success
            assert_template :new
          end
        end
      
        context "when study is inactive" do
          setup do
            @study = Factory(:study, :state => "inactive")
            @workflow = Factory :submission_workflow
            get :new, :study_id => @study.id, :workflow_id => @workflow.id
          end
    
          should_redirect_to("studies") {studies_url}
        end
      end
    end

    context "#create" do
      setup do
        @user = Factory :owner
        @controller.stubs(:logged_in?).returns(@user)
        @controller.stubs(:current_user).returns(@user)
        @study = Factory :study
        @project = Factory :project

        @asset1 = Factory :asset, { :sample => Factory(:sample) }
        @asset2 = Factory :asset, { :sample => Factory(:sample) }
        @asset3 = Factory :asset, { :sample => Factory(:sample) }
        @asset_group = Factory :asset_group
        @asset_group.assets << [@asset1,@asset2,@asset3]
        @request_type = Factory :request_type, :name => "test type"
        @workflow = Factory :submission_workflow
        @submission_template = Factory :submission_template

        @request_params = {
          "request_metadata_attributes" => {
            "library_type"=>"Standard",
            "fragment_size_required_from"=>"5",
            "fragment_size_required_to"=>"6",
            "read_length"=>"37"
          }
        }
        @submission_count = Submission.count
      end

      context "with quota available" do
        setup do
          @project.quotas.create(:request_type => @request_type, :limit => @asset_group.assets.size)
        end
        context "accessioning enforced and data release enforced" do
          setup do
            @study.enforce_data_release = true
            @study.enforce_accessioning = true
            @study.save!
          end

          # NOTE: 'data release is required on a study, so it can't not be filled in'
          
          context "where data release is set to open" do
            setup do
              @study.study_metadata.data_release_study_type.name = 'genomic sequencing'
              @study.study_metadata.data_release_strategy        = 'open'
              @study.study_metadata.data_release_timing          = 'standard'
              @study.study_metadata.study_type = StudyType.find_by_name("Not specified")
              @study.study_metadata.data_release_study_type = DataReleaseStudyType.find_by_name('genomic sequencing') 
              
            end
            context "study has accession number" do
              setup do
                @study.study_metadata.study_ebi_accession_number = "ERP0000001"
                @study.save!
              end
              context "and no samples in asset group have accessions" do
                setup do
                  post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                
                should "not have a successful submission" do
                  assert_not_nil @controller.session[:flash][:error].grep /Study and all samples must have accession numbers/
                  assert_equal @submission_count, Submission.count
                  assert_response :redirect
                  assert_redirected_to @submission_template ?  new_study_workflow_submission_path(@study, @workflow, :submission_template_id => @submission_template.id): new_study_workflow_submission_path(@study, @workflow) 
                end

              end
              context "and 1 sample in asset group has an accession and the rest dont" do
                setup do
                  @asset2.sample.sample_metadata.sample_ebi_accession_number = "ERS0000001"
                  @asset2.sample.save!
                  post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                should "not have a successful submission" do
                  assert_not_nil @controller.session[:flash][:error].grep /Study and all samples must have accession numbers/
                  assert_equal @submission_count, Submission.count
                  assert_response :redirect
                  assert_redirected_to @submission_template ?  new_study_workflow_submission_path(@study, @workflow, :submission_template_id => @submission_template.id): new_study_workflow_submission_path(@study, @workflow) 
                end
              end
              context "and all samples in asset group have accessions" do
                setup do
                  @asset_group.assets.each do |asset|
                    asset.sample.sample_metadata.sample_ebi_accession_number = "ERS0000001"
                    asset.sample.save!
                  end
                  post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                should_have_successful_submission
              end
            end
            context "study doesnt have accession number" do
              setup do
                post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
              end
              should "not have a successful submission" do
                assert_not_nil @controller.session[:flash][:error].grep /Study and all samples must have accession numbers/
                assert_equal @submission_count, Submission.count
                assert_response :redirect
                assert_redirected_to @submission_template ?  new_study_workflow_submission_path(@study, @workflow, :submission_template_id => @submission_template.id): new_study_workflow_submission_path(@study, @workflow) 
              end
            end
          end

          context "where data release is set to managed" do
            setup do
              @study.study_metadata.data_release_study_type = DataReleaseStudyType.find_by_name('transcriptomics')
              @study.study_metadata.data_release_strategy      = 'managed'
              @study.study_metadata.data_release_timing        = 'standard'

              @study.study_metadata.data_release_prevention_reason = 'legal'
              @study.study_metadata.data_release_prevention_approval = 'Yes'
              @study.study_metadata.data_release_prevention_reason_comment = 'It just is ok?'
              @study.study_metadata.study_type = StudyType.find_by_name("Not specified")
 
              
              @study.save!
            end
            context "and study has accession number" do
              setup do
                @study.study_metadata.study_ebi_accession_number = "ERP0000001"
                @study.save!
              end
              context "and no samples in asset group have accessions" do
                setup do
                  post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                should_have_successful_submission
              end
              context "and 1 sample in asset group has an accession and the rest dont" do
                setup do
                  @asset2.sample.sample_metadata.sample_ebi_accession_number = "ERS0000001"
                  post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                should_have_successful_submission
              end
              context "and all samples in asset group have accessions" do
                setup do
                  @asset_group.assets.each do |asset|
                    asset.sample.sample_metadata.sample_ebi_accession_number = "ERS0000001"
                  end
                  post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                should_have_successful_submission
              end
            end

            context "study doesnt have accession number" do
              setup do
                post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :project_name => @project.name,  :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
              end
              should_have_successful_submission
            end
          end
        end
        context "accessioning turned off" do
          setup do
            @study.enforce_accessioning = false
            @study.save!
          end
          context "data release not enforced" do
            setup do
              @study.enforce_data_release = false
              @study.save!
              post :create, :submission => {}, :asset_group => @asset_group.id.to_s,:project_name => @project.name, :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
            end
            should_have_successful_submission
          end

          # NOTE: 'data release' is required on a study, so it can't not be filled in
        end
      end

      context "one submission when no quota is available" do
        setup do
          @study.enforce_data_release = false
          @study.enforce_accessioning = false
          @project.enforce_quotas = true
          @project.save!
          @study.save!
          @project.quotas.create(:request_type => @request_type, :limit => 0)
          post :create, :submission => {}, :asset_group => @asset_group.id.to_s, :project_name => @project.name, :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
        end
        should "not have a successful submission" do
          assert_not_nil @controller.session[:flash][:error].grep /Insufficient quota for test type/
          assert_equal @submission_count, Submission.count
          assert_response :redirect
          assert_redirected_to @submission_template ?  new_study_workflow_submission_path(@study, @workflow, :submission_template_id => @submission_template.id): new_study_workflow_submission_path(@study, @workflow) 
        end
      end

      context "empty params" do
        should "raise an error" do
          assert_raise ActiveRecord::RecordNotFound do
            post :create, :submission => {}, :asset_group => "" ,:project_name => @project.name, :study_id => "", :workflow_id => "", "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}},  :request => ""
          end
        end
      end

      context "empty items and requests" do
        setup do
          @item_params = {}
          @request_params = {}
        end

        should "not raise an error and create submission" do
          assert_nothing_raised do
            post(
              :create,
              :submission => {},
              :asset_group => @asset_group.id.to_s,
              :project_name => @project.name,
              :study_id => @study.id,
              :workflow_id => @workflow.id,
              :request_type => {"0"=>{"request_type_id"=>"#{@request_type.id}"}},
              :request => @item_params,
              :submission_template_id => @submission_template.id
            )
          end
        end
      end
    end
  end
end
