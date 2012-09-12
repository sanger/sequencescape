require "test_helper"

# Re-raise errors caught by the controller.
class Studies::Workflows::SubmissionsController; def rescue_action(e) raise e end; end

class Studies::Workflows::SubmissionsControllerTest < ActionController::TestCase
  # temporary hack to emulate old behavior
  # of submission build directly
  def create_and_submit(args)
    last_submission = Submission.last
    post :create,  args.merge(:build_submission => "yes", :order_study_id => args[:study_id])
    if submission=Submission.last && submission != last_submission
      post :submit, :id => submission.id
    end
  end
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

            get :new, :study_id => @study.id, :workflow_id => @workflow.id, :submission_template_id => @submission_template.id
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

        @asset1 = Factory(:sample_tube)
        @asset2 = Factory(:sample_tube)
        @asset3 = Factory(:sample_tube)
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
                  create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end

                should "not have a successful submission" do
                  assert_contains(@controller.action_flash[:error], 'Study and all samples must have accession numbers')
                  assert_equal @submission_count, Submission.count
                end

              end
              context "and 1 sample in asset group has an accession and the rest dont" do
                setup do
                  @asset2.primary_aliquot.sample.sample_metadata.update_attributes!(:sample_ebi_accession_number => 'ERS000001')
                  create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                should "not have a successful submission" do
                  assert_contains(@controller.action_flash[:error], 'Study and all samples must have accession numbers')
                  assert_equal @submission_count, Submission.count
                end
              end
              context "and all samples in asset group have accessions" do
                setup do
                  @asset_group.assets.each do |asset|
                    asset.primary_aliquot.sample.sample_metadata.update_attributes!(:sample_ebi_accession_number => 'ERS000001')
                  end
                end
                #should_have_successful_submission
              end
            end
            context "study doesnt have accession number" do
              setup do
                create_and_submit :order => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
              end
              should "not have a successful submission" do
                assert_contains(@controller.action_flash[:error], 'Study and all samples must have accession numbers')
                assert_equal @submission_count, Submission.count
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
                  create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                #should_have_successful_submission
              end
              context "and 1 sample in asset group has an accession and the rest dont" do
                setup do
                  @asset2.primary_aliquot.sample.sample_metadata.sample_ebi_accession_number = "ERS0000001"
                  create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                #should_have_successful_submission
              end
              context "and all samples in asset group have accessions" do
                setup do
                  @asset_group.assets.each do |asset|
                    asset.primary_aliquot.sample.sample_metadata.sample_ebi_accession_number = "ERS0000001"
                  end
                  create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :study_id => @study.id, :project_name => @project.name,  :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
                end
                #should_have_successful_submission
              end
            end

            context "study doesnt have accession number" do
              setup do
                create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :project_name => @project.name,  :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
              end
              #should_have_successful_submission
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
              create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s,:project_name => @project.name, :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
            end
            #should_have_successful_submission
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
          #we add a dummy quota so the project seems to have been setup
          @project.quotas.create(:request_type => Factory(:request_type), :limit => 1)
          create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :project_name => @project.name, :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
        end
        should "not have a successful submission" do
          assert_contains(@controller.action_flash.values, 'Insufficient quota for test type (require 3 but only 0 remaining)')
          assert_equal @submission_count, Submission.count
        end
      end

      context "one submission when no quota have been setup" do
        setup do
          @study.enforce_data_release = false
          @study.enforce_accessioning = false
          @project.enforce_quotas = true
          @project.save!
          @study.save!
          @project.quotas.create(:request_type => @request_type, :limit => 0)
          create_and_submit  :order => {}, :asset_group => @asset_group.id.to_s, :project_name => @project.name, :study_id => @study.id, :workflow_id => @workflow.id, "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}}, :request => @request_params, :submission_template_id => @submission_template.id
        end
        should "not have a successful submission" do
          assert_contains(@controller.action_flash[:error], 'Quotas are being enforced but have not been setup')
          assert_equal @submission_count, Submission.count
        end
      end
      context 'required but empty parameters' do
        setup do
          @valid_parameters = {
            :order => {},
            :asset_group => @asset_group.id.to_s,
            :study_id => @study.id,
            :project_name => @project.name,
            :workflow_id => @workflow.id,
            "request_type" => {"0"=>{"request_type_id"=>"#{@request_type.id}"}},
            :request => @request_params,
            :submission_template_id => @submission_template.id
          }
        end

        [ :study_id, :workflow_id ].each do |parameter|
          should "raise an error if #{parameter.inspect} is blank" do
            assert_raise ActiveRecord::RecordNotFound do
              create_and_submit  @valid_parameters.merge(parameter => '')
            end
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
            create_and_submit(:order => {},
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
