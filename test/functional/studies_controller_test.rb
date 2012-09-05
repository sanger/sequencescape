require "test_helper"
require 'studies_controller'

# Re-raise errors caught by the controller.
class StudiesController; def rescue_action(e) raise e end; end

class StudiesControllerTest < ActionController::TestCase
  context "StudiesController" do
    setup do
      @controller = StudiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test(
      'study', {
        :defaults => {:name => "study name"},
        :user => :admin,
        :other_actions => ['properties', 'study_status'],
        :ignore_actions => ['show', 'create', 'update', 'destroy'],
        :formats => ['xml']
      }
    )
  end

  context "create a study - custom" do
    setup do
      @controller = StudiesController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      @user = Factory :user
      @user.has_role('owner')
      @controller.stubs(:logged_in?).returns(@user)
      @controller.stubs(:current_user).returns(@user)
    end

    context "#new" do
      setup do
        get :new
      end

      should_respond_with :success
      should_render_template :new
    end

    context "#new_plate_submission" do
      setup do
        @study = Factory :study
        @project = Factory :project
        @user.is_administrator
        @user.save
        get :new_plate_submission, :id => @study.id
      end

      should_respond_with :success
      should_render_template :new_plate_submission
    end

    context "#create" do
      setup do
        @request_type_1 = Factory :request_type
      end

      context "successfully create a new study" do
        setup do
          post :create, "study" => {
            "name" => "hello",
            "reference_genome_id" => ReferenceGenome.find_by_name("").id,
            'study_metadata_attributes' => {
              'faculty_sponsor' => FacultySponsor.create!(:name => 'Me'),
              'study_description' => 'some new study',
              'contains_human_dna' => 'No',
              'contaminated_human_dna' => 'No',
              'commercially_available' => 'No',
              'data_release_study_type' => DataReleaseStudyType.find_by_name('genomic sequencing'),
              'data_release_strategy' => 'open',
              'study_type' => StudyType.find_by_name("Not specified")
            }
          }
        end

        should_set_the_flash_to "Your study has been created"
        should_redirect_to("study path") { study_path(Study.last) }
        should_change('Study.count', 1) { Study.count }
      end

      context "fail to create a new study" do
        setup do
          post :create, "study" => { "name" => "hello 2" }
        end

        should_render_template :new
        should_not_change('Study.count') { Study.count }

        should 'set a message for the error' do
          assert_contains(@controller.action_flash.values, 'Problems creating your new study')
        end
      end

      context "create a new study using permission allowed (not required)" do
        setup do
          post :create, "study" => {
            "name" => "hello 3",
            "reference_genome_id" => ReferenceGenome.find_by_name("").id,
            'study_metadata_attributes' => {
              'faculty_sponsor' => FacultySponsor.create!(:name => 'Me'),
              'study_description' => 'some new study',
              'contains_human_dna' => 'No',
              'contaminated_human_dna' => 'No',
              'commercially_available' => 'No',
              'data_release_study_type' => DataReleaseStudyType.find_by_name('genomic sequencing'),
              'data_release_strategy' => 'open',
              'study_type' => StudyType.find_by_name("Not specified")
            }
          }
        end

        should_change('Study.count', 1) { Study.count }
        should_redirect_to("study path") { study_path(Study.last) }
        should_set_the_flash_to "Your study has been created"
      end

    end

  end
end
