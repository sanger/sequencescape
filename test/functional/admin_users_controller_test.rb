# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'
require 'samples_controller'

class Admin::UsersControllerTest < ActionController::TestCase
  context 'Admin Users controller' do
    setup do
      @controller = Admin::UsersController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test(
      'user', ignore_actions: ['update'],
              actions: ['show', 'edit', 'index'],
              formats: ['html'],
              defaults: { login: 'abc1234' },
              user: -> { FactoryGirl.create(:admin) },

              # Setup needed because 'edit' assumes presence of at least one Study and Project
              setup: -> { FactoryGirl.create(:study); FactoryGirl.create(:project) }
    )

    context '#filter' do
      setup do
        @user = FactoryGirl.create :user
        @admin = FactoryGirl.create :admin

        session[:user] = @admin

        @user_to_find = FactoryGirl.create :user, first_name: 'Some', last_name: 'Body', login: 'sb1'
        @another_user = FactoryGirl.create :user, first_name: 'No', last_name: 'One', login: 'no1'
      end

      should 'find a user based on name' do
        post :filter, q: 'Some'

        @users = assigns(:users)
        assert_equal @user_to_find, @users.first
      end

      should 'find a user based on login' do
        post :filter, q: 'sb'

        @users = assigns(:users)
        assert_equal @user_to_find, @users.first
      end

      should 'find multiple users with shared characters in their logins' do
        post :filter, q: '1'

        @users = assigns(:users)
        assert @users.detect { |u| u == @user_to_find }
        assert @users.detect { |u| u == @another_user }
      end

      should 'find multiple users with shared characters in their names' do
        post :filter, q: 'o'

        @users = assigns(:users)
        assert @users.detect { |u| u == @user_to_find }
        assert @users.detect { |u| u == @another_user }
      end
    end
  end
end
