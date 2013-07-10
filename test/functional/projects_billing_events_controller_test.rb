require "test_helper"

# Re-raise errors caught by the controller.
class Projects::BillingEventsController; def rescue_action(e) raise e end; end

class Projects::BillingEventsControllerTest < ActionController::TestCase
  context "Projects::BillingEvents controller" do
    setup do
      @controller = Projects::BillingEventsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @logged_in_users_email = "bill@example.com"
      @user     = Factory :user, :email => @logged_in_users_email
      @controller.stubs(:current_user).returns(@user)
      @project  = Factory :project
    end
    should_require_login

    context "#index" do
      context "requesting html" do
        setup do
          get :index, :project_id => @project.id
        end

        should_respond_with :success
        should_render_template "index"
      end

      context "requesting xml" do
        setup do
          get :index, :project_id => @project.id, :format => "xml"
        end

        should_respond_with :success
        should_respond_with_content_type :xml
      end

      context "requesting json" do
        setup do
          get :index, :project_id => @project.id, :format => "json"
        end

        should_respond_with :success
        should_respond_with_content_type :json
      end
    end

    context "#new" do
      setup do
        get :new, :project_id => @project.id
      end

      should_respond_with :success
      should_render_template "new"
    end

    context "#show" do
      setup do
        @billing_event = Factory :billing_event
      end
      context "requesting html" do
        setup do
          get :show, :project_id => @project, :id => @billing_event
        end

        should_respond_with :success
        should_render_template "show"
      end

      context "requesting xml" do
        setup do
          get :show, :project_id => @project, :id => @billing_event, :format => "xml"
        end

        should_respond_with :success
        should_respond_with_content_type :xml
      end

      context "requesting json" do
        setup do
          get :show, :project_id => @project, :id => @billing_event, :format => "json"
        end

        should_respond_with :success
        should_respond_with_content_type :json
      end
    end

    context "#create" do
      context "with valid parameters" do
        setup do
          @s_request  = Factory :request
          @billing_attributes = Factory.attributes_for(:billing_event, :project_id => @project.id, :request_id => @s_request.id)
        end
        context "POSTed as form" do
          context "with supplied email" do
            setup do
              @billing_attributes["created_by"] = "other@example.com"
              post :create, :project_id => @project.id, :billing_event => @billing_attributes
            end
            should_set_the_flash_to Regexp.new("#{I18n.t('projects.billing_events.created', :ref => '')}")
            should_respond_with :redirect
            should "still set the created_at to the logged in user" do
              assert_equal @logged_in_users_email, assigns(:billing_event).created_by
            end
          end
          context "without supplied email" do
            setup do
              @billing_attributes.delete(:created_by)
              post :create, :project_id => @project.id, :billing_event => @billing_attributes
            end
            should_set_the_flash_to Regexp.new("#{I18n.t('projects.billing_events.created', :ref => '')}")
            should_respond_with :redirect
            should "still set the created_at to the logged in user" do
              assert_equal @logged_in_users_email, assigns(:billing_event).created_by
            end
          end
        end
        context "POSTed as XML" do
          setup do
            post :create, :project_id => @project.id, :format => "xml", :billing_event => @billing_attributes
            @billing_event = assigns(:billing_event)
          end

          should_respond_with :created
          should "return location header to new resource" do
            assert_equal project_billing_event_url(@project.id, @billing_event.id), @response.location
          end
          should "set the created_at as supplied" do
            assert_equal @billing_attributes[:created_by], assigns(:billing_event).created_by
          end
        end
        context "POSTed as JSON" do
          setup do
            post :create, :project_id => @project.id, :format => "json", :billing_event => @billing_attributes
            @billing_event = assigns(:billing_event)
          end

          should_respond_with :created
          should "return location header to new resource" do
            assert_equal project_billing_event_url(@project.id, @billing_event.id), @response.location
          end
        end

      end

      context "with invalid parameters" do
        setup do
          @billing_attributes = {:project => "good"}
        end
        context "POSTed as form" do
          setup do
            post :create, :project_id => @project.id, :billing_event => @billing_attributes
          end

          should_set_the_flash_to I18n.t("projects.billing_events.not_created")
          should_respond_with :success
          should_render_template :new
        end
        context "POSTed as XML" do
          setup do
            post :create, :project_id => @project.id, :format => "xml", :billing_event => @billing_attributes
          end

          should_respond_with :bad_request
          should_respond_with_content_type :xml
        end
        context "POSTed as JSON" do
          setup do
            post :create, :project_id => @project.id, :format => "json", :billing_event => @billing_attributes
          end

          should_respond_with :bad_request
          should_respond_with_content_type :json
        end
      end
    end
  end
end
