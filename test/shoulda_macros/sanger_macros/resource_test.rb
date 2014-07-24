module Sanger
  module Testing
    module Controller
      module Macros
        def resource_test(resource_name, params = {})
          params.symbolize_keys!
          resource_name = resource_name.to_sym

          restful_actions = ['index','new','create','show','update','destroy','edit']
          ignore_actions  = params[:ignore_actions] || []
          actions         = params[:actions] || (restful_actions - ignore_actions)
          raise Exception.new, ":actions need to be an Array" unless actions.instance_of?(Array)

          other_actions   = params[:other_actions] || []
          formats         = params[:formats] || ['html','xml', 'json']

          context 'should be a resource' do
            setup do
              @factory_options = params[:defaults] || {}
              @create_options  = params[:defaults] || {}
              @input_params = {}
            end

            show_url              = "#{resource_name}_path(@#{resource_name})"
            index_url             = "#{resource_name.to_s.pluralize}_path"
            grand_parent_resource = params[:grand_parent]
            parent_resource       = params[:parent]

            if grand_parent_resource && parent_resource
              show_url  = "#{grand_parent_resource}_#{parent_resource}_#{resource_name}_path(@#{grand_parent_resource}, @#{parent_resource}, @#{resource_name})"
              index_url = "#{grand_parent_resource}_#{parent_resource}_#{resource_name.to_s.pluralize}_path(@#{grand_parent_resource}, @#{parent_resource})"

              setup do
                grand_parent = Factory grand_parent_resource
                parent       = Factory parent_resource

                @factory_options.merge!(
                  grand_parent_resource.to_sym => grand_parent,
                  parent_resource.to_sym       => parent
                )

                @input_params.merge!(
                  "#{grand_parent_resource}_id" => grand_parent.id,
                  "#{parent_resource}_id"       => parent.id
                )
              end
            elsif parent_resource
              show_url  = "#{parent_resource}_#{resource_name}_path(@#{parent_resource}, @#{resource_name})"
              index_url = "#{parent_resource}_#{resource_name.to_s.pluralize}_path(@#{parent_resource})"

              setup do
                parent       = Factory parent_resource

                @factory_options.merge!(
                  parent_resource.to_sym => parent
                )

                @input_params.merge!(
                  "#{parent_resource}_id" => parent.id
                )
              end
            end

            setup    { params[:setup].call    } if params.key?(:setup)
            teardown { params[:teardown].call } if params.key?(:teardown)

            context "when logged in" do
              setup do
                # Determine what to do with the :user parameter passed.  If it's a Symbol then it's a factory; if it's nil we
                # default to the :user factory; if it's a proc then we can call it; otherwise we should explode in the face of
                # the developer who is potentially creating ActiveRecord objects outside the test transaction!
                user_details = params[:user] || :user
                @user = case
                  when user_details.is_a?(Symbol) then Factory(user_details)
                  when user_details.is_a?(Proc) then user_details.call
                  else raise StandardError, "You are potentially creating objects outside of a transaction: #{ user_details.inspect }"
                end

                # All our things need a user to be logged in
                @controller.stubs(:current_user).returns(@user)
                @controller.stubs(:logged_in?).returns(@user)
              end
              if actions.include?('index')
                context "should get index" do
                  setup do
                    get :index, @input_params
                  end
                  should_respond_with :success
                  should_render_template :index
                end
              end

              if actions.include?('new')
                context "should get new" do
                  setup do
                    get :new, @input_params
                  end
                  should_respond_with :success
                end
              end

              if actions.include?('create')
                context "should create" do
                  setup do
                    local_params = @input_params
                    local_params[resource_name] = @create_options
                    post :create, local_params
                  end
                  #assert_valid eval "@#{resource_name}"
                  should_redirect_to("show page"){ eval(show_url) }
                end
              end

              if actions.include?('show')
                context "should show #{resource_name}" do
                  setup do
                    @object = Factory resource_name, @factory_options
                    local_params = @input_params
                    local_params[:id] = @object.id
                    get :show, local_params
                  end
                  should_respond_with :success
                end
              end

              if actions.include?('edit')
                context "should get edit" do
                  setup do
                    @object = Factory resource_name, @factory_options
                    local_params = @input_params
                    local_params[:id] = @object.id
                    get :edit, local_params
                  end
                  should_respond_with :success
                end
              end

              if actions.include?('update')
                context "should update" do
                  setup do
                    @object = Factory resource_name
                    local_params = @input_params
                    local_params[resource_name] = @create_options
                    local_params[:id] = @object.id
                    put :update, local_params
                  end
                  should_redirect_to("show page"){ eval(show_url) }
                end
              end

              if actions.include?('destroy')
                context "should destroy" do
                  setup do
                    @object = Factory resource_name
                    local_params = @input_params
                    local_params[:id] = @object.id
                    delete :destroy, local_params
                  end
                  should_redirect_to("index page"){ eval(index_url) }
                end

                # context "destroy without object in database" do
                #   setup do
                #     assert_raise ActiveRecord::RecordNotFound do
                #       # Should this be a POST/PUT?
                #       delete :destroy, :id => -1
                #     end
                #   end
                #   should_not_set_the_flash
                # end
              end

              untested_actions = (restful_actions - ignore_actions) - actions
              context "should not have untested action" do
                untested_actions.each do |action|
                  should "#{action}" do
                    assert_raise ActionController::UnknownAction do
                      get action
                    end
                  end
                end
              end unless untested_actions.empty?

              context "SequenceScape actions" do
                if other_actions.include?('status')
                  context "should show status" do
                    setup do
                      @object = Factory resource_name
                      get :status, :id => @object.id
                    end
                    should_respond_with :success
                  end
                end
              end
              context "API access" do
                if formats.include?('xml')
                  if actions.include?('index')
                    context "when using XML to access a list " do
                      setup do
                        @object = Factory resource_name, @factory_options
                        @request.accept = "application/xml"
                        local_params = @input_params
                        get :index, local_params
                      end
                      should_respond_with :success
                      should "have api version attribute on root object" do
                        assert_tag :tag => "#{resource_name.to_s.pluralize}", :attributes => {:api_version => "0.6"}
                        assert_tag :tag => "#{resource_name.to_s.pluralize}"
                      end
                    end
                  end
                  if actions.include?('show')
                    context "when using XML to access a single object" do
                      setup do
                        @request.accept = "application/xml"
                        @object = Factory resource_name, @factory_options
                        local_params = @input_params
                        local_params[:id] = @object.id
                        get :show, local_params
                      end
                      should_respond_with :success
                      should "show xml" do
                        assert_tag :tag => "#{resource_name}", :attributes => {:api_version => RELEASE.api_version}
                        assert_tag :tag => "#{resource_name}"
                      end
                    end
                  end
                end
                if formats.include?('json')
                  if actions.include?('index')
                    context "when using JSON to access a list " do
                      setup do
                        @object = Factory resource_name, @factory_options
                        @request.accept = "text/x-json"
                        local_params = @input_params
                        get :index, local_params
                      end
                      should_respond_with :success
                      should "be JSON" do
                        assert ActiveSupport::JSON.decode(@response.body).size > 0
                      end
                    end
                  end
                  if actions.include?('show')
                    context "when using JSON to access a single object" do
                      setup do
                        @object = Factory resource_name, @factory_options
                        @request.accept = "text/x-json"
                        local_params = @input_params
                        local_params[:id] = @object.id
                        get :show, local_params
                      end
                      should_respond_with :success
                      should "be JSON" do
                        assert_equal @object.to_json, @response.body
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
