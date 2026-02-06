# frozen_string_literal: true

require 'test_helper'

module Admin
  class UsersControllerTest < ActionController::TestCase
    context 'Admin Users controller' do
      setup do
        @controller = Admin::UsersController.new
        @request = ActionController::TestRequest.create(@controller)
      end

      should_require_login

      resource_test(
        'user',
        ignore_actions: ['update'],
        actions: %w[show edit index],
        formats: ['html'],
        defaults: {
          login: 'abc1234'
        },
        user: :admin,
        # Setup needed because 'edit' assumes presence of at least one Study and Project
        setup_with:
          lambda do
            FactoryBot.create(:study)
            FactoryBot.create(:project)
          end
      )

      context '#filter' do
        setup do
          @user = FactoryBot.create(:user)
          @admin = FactoryBot.create(:admin)

          session[:user] = @admin

          @user_to_find = FactoryBot.create(:user, first_name: 'Some', last_name: 'Body', login: 'sb1')
          @another_user = FactoryBot.create(:user, first_name: 'No', last_name: 'One', login: 'no1')
        end

        should 'find a user based on name' do
          post :filter, params: { q: 'Some' }

          @users = assigns(:users)

          assert_equal @user_to_find, @users.first
        end

        should 'find a user based on login' do
          post :filter, params: { q: 'sb' }

          @users = assigns(:users)

          assert_equal @user_to_find, @users.first
        end

        should 'find multiple users with shared characters in their logins' do
          post :filter, params: { q: '1' }

          @users = assigns(:users)

          assert @users.detect { |u| u == @user_to_find }
          assert @users.detect { |u| u == @another_user }
        end

        should 'find multiple users with shared characters in their names' do
          post :filter, params: { q: 'o' }

          @users = assigns(:users)

          assert @users.detect { |u| u == @user_to_find }
          assert @users.detect { |u| u == @another_user }
        end
      end
    end
  end
end
