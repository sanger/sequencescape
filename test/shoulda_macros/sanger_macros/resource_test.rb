# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

module Sanger
  module Testing
    module Controller
      module Macros
        RESTFUL_ACTIONS = %w(index new create show update destroy edit).freeze

        def resource_test(resource_name, params = {})
          params.symbolize_keys!
          resource_name = resource_name.to_sym

          ignore_actions   = params[:ignore_actions] || []
          actions          = params[:actions] || (RESTFUL_ACTIONS - ignore_actions)
          untested_actions = (RESTFUL_ACTIONS - ignore_actions) - actions
          path_prefix      = params[:with_prefix] || ''

          raise Exception.new, ':actions need to be an Array' unless actions.instance_of?(Array)

          other_actions   = params[:other_actions] || []
          formats         = params[:formats] || ['html', 'xml', 'json']

          context 'should be a resource' do
            setup do
              @factory_options = params[:defaults] || {}
              @create_options  = params[:defaults] || {}
              @update_options  = (params[:defaults] || {}).reject do |k, _v|
                params.fetch(:protect_on_update, []).include?(k)
              end.deep_merge!(params.fetch(:extra_on_update, {}))
              @input_params = {}
            end

            show_url              = "#{path_prefix}#{resource_name}_path(@object)"
            index_url             = "#{path_prefix}#{resource_name.to_s.pluralize}_path"
            grand_parent_resource = params[:grand_parent]
            parent_resource       = params[:parent]

            if grand_parent_resource && parent_resource
              show_url  = "#{grand_parent_resource}_#{parent_resource}_#{resource_name}_path(@#{grand_parent_resource}, @#{parent_resource}, @object)"
              index_url = "#{grand_parent_resource}_#{parent_resource}_#{resource_name.to_s.pluralize}_path(@#{grand_parent_resource}, @#{parent_resource})"

              setup do
                grand_parent = create grand_parent_resource
                parent       = create parent_resource

                @factory_options[grand_parent_resource.to_sym] = grand_parent
                @factory_options[parent_resource.to_sym] = parent

                @input_params.merge!(
                  "#{grand_parent_resource}_id" => grand_parent.id,
                  "#{parent_resource}_id"       => parent.id
                )
              end
            elsif parent_resource
              show_url  = "#{parent_resource}_#{resource_name}_path(@#{parent_resource}, @object)"
              index_url = "#{parent_resource}_#{resource_name.to_s.pluralize}_path(@#{parent_resource})"

              setup do
                parent = create parent_resource

                @factory_options[parent_resource.to_sym] = parent

                @input_params.merge!(
                  "#{parent_resource}_id" => parent.id
                )
              end
            end

            setup    { params[:setup].call    } if params.key?(:setup)
            teardown { params[:teardown].call } if params.key?(:teardown)

            context 'when logged in' do
              setup do
                # Determine what to do with the :user parameter passed.  If it's a Symbol then it's a factory; if it's nil we
                # default to the :user factory; if it's a proc then we can call it; otherwise we should explode in the face of
                # the developer who is potentially creating ActiveRecord objects outside the test transaction!
                user_details = params[:user] || :user
                @user = case
                        when user_details.is_a?(Symbol) then create(user_details)
                        when user_details.is_a?(Proc) then user_details.call
                        else raise StandardError, "You are potentially creating objects outside of a transaction: #{user_details.inspect}"
                        end

                # All our things need a user to be logged in
                session[:user] = @user.id
                @controller.stubs(:logged_in?).returns(@user)
              end
              if actions.include?('index')
                context 'should get index' do
                  setup do
                    get :index, @input_params
                  end
                  should respond_with :success
                  should render_template :index
                end
              end

              if actions.include?('new')
                context 'should get new' do
                  setup do
                    get :new, @input_params
                  end
                  should respond_with :success
                end
              end

              if actions.include?('create')
                context 'should create' do
                  setup do
                    @input_params[resource_name] = @create_options
                    post :create, @input_params
                  end
                  # assert eval "@object".valid?
                  should redirect_to('show page') { eval(show_url) }
                end
              end

              if actions.include?('show')
                context "should show #{resource_name}" do
                  setup do
                    @object = create resource_name, @factory_options
                    @input_params[:id] = @object.id
                    get :show, @input_params
                  end
                  should respond_with :success
                end
              end

              if actions.include?('edit')
                context 'should get edit' do
                  setup do
                    @object = create resource_name, @factory_options
                    @input_params[:id] = @object.id
                    get :edit, @input_params
                  end
                  should respond_with :success
                end
              end

              if actions.include?('update')
                context 'should update' do
                  setup do
                    @object = create resource_name
                    @input_params[resource_name] = @create_options
                    @input_params[:id] = @object.id
                    put :update, @input_params
                  end
                  should redirect_to('show page') { eval(show_url) }
                end
              end

              if actions.include?('destroy')
                context 'should destroy' do
                  setup do
                    @object = create resource_name
                    @input_params[:id] = @object.id
                    delete :destroy, @input_params
                  end
                  should redirect_to('index page') { eval(index_url) }
                end
              end

              context 'should not have untested action' do
                untested_actions.each do |action|
                  should action.to_s do
                    assert_raise AbstractController::ActionNotFound do
                      get action
                    end
                  end
                end
              end unless untested_actions.empty?

              context 'SequenceScape actions' do
                if other_actions.include?('status')
                  context 'should show status' do
                    setup do
                      @object = create resource_name
                      get :status, id: @object.id
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
                        @object = create resource_name, @factory_options
                        @request.accept = 'application/xml'
                        get :index, @input_params
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
                        @object = create resource_name, @factory_options
                        @input_params[:id] = @object.id
                        get :show, @input_params
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
                        @object = create resource_name, @factory_options
                        @request.accept = 'text/x-json'
                        get :index, @input_params
                      end
                      should respond_with :success
                      should 'be JSON' do
                        assert ActiveSupport::JSON.decode(@response.body).size > 0
                      end
                    end
                  end
                  if actions.include?('show')
                    context 'when using JSON to access a single object' do
                      setup do
                        @object = create resource_name, @factory_options
                        @request.accept = 'text/x-json'
                        @input_params[:id] = @object.id
                        get :show, @input_params
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
      end
    end
  end
end
