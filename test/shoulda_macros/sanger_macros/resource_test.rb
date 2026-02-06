# frozen_string_literal: true

# This is pretty convoluted, and pushes some of our cops metric up massively
# We disable them here, rather than relying on todo as these metric work on a
# worst case basis, and we really don't want things getting as convoluted as this
# elsewhere.
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
module Sanger
  module Testing
    module Controller
      module Macros # rubocop:todo Metrics/ModuleLength
        RESTFUL_ACTIONS = %w[index new create show update destroy edit].freeze

        # rubocop:todo Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        def resource_test(resource_name, kwords)
          ignore_actions = kwords[:ignore_actions] || []
          actions = kwords[:actions] || (RESTFUL_ACTIONS - ignore_actions)
          with_prefix = kwords[:with_prefix] || ''
          other_actions = kwords[:other_actions] || []
          formats = kwords[:formats] || %w[html xml json]
          defaults = kwords[:defaults] || {}
          protect_on_update = kwords[:protect_on_update] || []
          extra_on_update = kwords[:extra_on_update] || {}
          parent = kwords[:parent] || nil
          setup_with = kwords[:setup_with] || nil
          teardown_with = kwords[:teardown_with] || nil
          user = kwords[:user] || :user

          resource_name = resource_name.to_sym

          untested_actions = (RESTFUL_ACTIONS - ignore_actions) - actions

          raise ':actions need to be an Array' unless actions.instance_of?(Array)

          context 'should be a resource' do
            setup do
              @factory_options = defaults
              @create_options = defaults
              @update_options = defaults.reject { |k, _v| protect_on_update.include?(k) }.deep_merge(extra_on_update) # rubocop:todo Style/HashExcept
              @input_params = {}
            end

            show_url = "#{with_prefix}#{resource_name}_path(@object)"
            index_url = "#{with_prefix}#{resource_name.to_s.pluralize}_path"
            parent_resource = parent

            if parent_resource
              show_url = "#{parent_resource}_#{resource_name}_path(@#{parent_resource}, @object)"
              index_url = "#{parent_resource}_#{resource_name.to_s.pluralize}_path(@#{parent_resource})"

              setup do
                parent = create(parent_resource)
                @factory_options[parent_resource.to_sym] = parent
                @input_params["#{parent_resource}_id"] = parent.id
              end
            end

            setup { setup_with.call } if setup_with
            teardown { teardown_with.call } if teardown_with

            context 'when logged in' do
              setup do
                # Create the user using the factory specified by the :user parameter
                # or fall back to the default :user factory
                @user = create(user)

                # All our things need a user to be logged in
                session[:user] = @user.id
              end
              if actions.include?('index')
                context 'should get index' do
                  setup { get :index, params: @input_params }
                  should respond_with :success
                  should render_template :index
                end
              end

              if actions.include?('new')
                context 'should get new' do
                  setup { get :new, params: @input_params }
                  should respond_with :success
                end
              end

              if actions.include?('create')
                context 'should create' do
                  setup do
                    @input_params[resource_name] = @create_options
                    post :create, params: @input_params
                  end
                  should redirect_to('show page') { eval(show_url) }
                end
              end

              if actions.include?('show')
                context "should show #{resource_name}" do
                  setup do
                    @object = create(resource_name, @factory_options)
                    @input_params[:id] = @object.id
                    get :show, params: @input_params
                  end
                  should respond_with :success
                end
              end

              if actions.include?('edit')
                context 'should get edit' do
                  setup do
                    @object = create(resource_name, @factory_options)
                    @input_params[:id] = @object.id
                    get :edit, params: @input_params
                  end
                  should respond_with :success
                end
              end

              if actions.include?('update')
                context 'should update' do
                  setup do
                    @object = create(resource_name)
                    @input_params[resource_name] = @create_options
                    @input_params[:id] = @object.id
                    put :update, params: @input_params
                  end
                  should redirect_to('show page') { eval(show_url) }
                end
              end

              if actions.include?('destroy')
                context 'should destroy' do
                  setup do
                    @object = create(resource_name)
                    @input_params[:id] = @object.id
                    delete :destroy, params: @input_params
                  end
                  should redirect_to('index page') { eval(index_url) }
                end
              end

              context 'should not have untested action' do
                untested_actions.each do |action|
                  should action.to_s do
                    @object = create(resource_name)
                    @input_params[:id] = @object.id
                    assert_raise AbstractController::ActionNotFound do
                      get action, params: @input_params
                    end
                  end
                end
              end

              context 'SequenceScape actions' do
                if other_actions.include?('status')
                  context 'should show status' do
                    setup do
                      @object = create(resource_name)
                      get :status, params: { id: @object.id }
                    end
                    should respond_with :success
                  end
                end
              end
              context 'API access' do
                if formats.include?('xml')
                  if actions.include?('index')
                    context 'when using XML to access a list ' do
                      setup do
                        @object = create(resource_name, @factory_options)
                        @request.accept = 'application/xml'
                        get :index, params: @input_params
                      end
                      should respond_with :success

                      should 'have api version attribute on root object' do
                        assert_select resource_name.to_s.pluralize do
                          assert_select "[api_version='0.6']"
                        end
                      end
                    end
                  end
                  if actions.include?('show')
                    context 'when using XML to access a single object' do
                      setup do
                        @request.accept = 'application/xml'
                        @object = create(resource_name, @factory_options)
                        @input_params[:id] = @object.id
                        get :show, params: @input_params
                      end
                      should respond_with :success
                      assert_select resource_name.to_s.pluralize do
                        assert_select "[api_version='0.6']"
                      end
                    end
                  end
                end
                if formats.include?('json')
                  if actions.include?('index')
                    context 'when using JSON to access a list ' do
                      setup do
                        @object = create(resource_name, @factory_options)
                        @request.accept = 'text/x-json'
                        get :index, params: @input_params
                      end
                      should respond_with :success

                      should 'be JSON' do
                        assert_operator ActiveSupport::JSON.decode(@response.body).size, :>, 0
                      end
                    end
                  end
                  if actions.include?('show')
                    context 'when using JSON to access a single object' do
                      setup do
                        @object = create(resource_name, @factory_options)
                        @request.accept = 'text/x-json'
                        @input_params[:id] = @object.id
                        get :show, params: @input_params
                      end
                      should respond_with :success

                      should 'be JSON' do
                        assert_equal @object.to_json, @response.body
                      end
                    end
                  end
                end
              end
            end
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
      end
    end
  end
end
# rubocop:enable Metrics/MethodLength, Metrics/AbcSize
