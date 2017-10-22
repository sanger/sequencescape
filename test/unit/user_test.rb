# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2013,2015 Genome Research Ltd.

require 'test_helper'

class UserTest < ActiveSupport::TestCase
  context 'A User' do
    context 'authenticate' do
      setup do
          @user = create :admin, login: 'xyz987', api_key: 'my_key', crypted_password: '1'
          @ldap = mock('LDAP')
          @ldap.stubs(:bind).returns(true)
          Net::LDAP.stubs(:new).returns(@ldap)

          @response = mock('Response')
          @response.stubs(:body).returns('{"valid":1,"username":"xyz987"}')
          Net::HTTP.stubs(:post_form).returns(@response)
      end

      should 'login_in_user' do
        assert_equal true, User.authenticate_with_ldap('someone', 'password')
      end
    end

    context 'is an administrator' do
      setup do
        @user = create :admin
      end

      should 'be able to access admin functions' do
        assert @user.administrator?
      end

      should 'be able to access manager functions' do
        assert @user.manager_or_administrator?
      end

      should 'have access to privileged functions' do
        assert @user.privileged?
      end
    end

    context 'is a manager' do
      setup do
        @user = create :manager
      end

      should 'not be able to access admin functions' do
        assert !@user.administrator?
      end

      should 'be able to access manager functions' do
        assert @user.manager_or_administrator?
      end

      should 'have be manager' do
        assert @user.manager?
      end

      should 'have access to privileged functions' do
        assert @user.privileged?
      end
    end

    context 'is an owner' do
      setup do
        @user = create :owner
      end

      should 'not be able to access admin functions' do
        assert !@user.administrator?
      end

      should 'not be able to access manager functions' do
        assert !@user.manager_or_administrator?
      end

      should 'not have access to privileged functions generally' do
        assert !@user.privileged?
      end
    end

    context 'admins and emails' do
      setup do
        admin = create :role, name: 'administrator'
        user1 = create :user, login: 'bla'
        user2 = create :user, login: 'wow'
        user2.roles << admin
        user1.roles << admin
      end

      should 'return all admins and associated email addresses' do
        assert_equal 2, User.all_administrators.size
        assert_equal 2, User.all_administrators_emails.size
        assert_equal true, User.all_administrators_emails.include?('wow@example.com')
        assert_equal true, User.all_administrators_emails.include?('bla@example.com')
      end
    end

    context '#name' do
      context 'when profile is complete' do
        setup do
          @user = create :user, first_name: 'Alan', last_name: 'Brown'
          assert @user.valid?
        end
        should 'return full name' do
          assert_equal 'Alan Brown', @user.name
        end
      end
      context 'when profile is incomplete' do
        setup do
          @user = create :user, login: 'abc123', first_name: 'Alan', last_name: nil
          assert @user.valid?
        end
        should 'return login' do
          assert_equal 'abc123', @user.name
        end
      end
    end

    context '#new_api_key' do
      setup do
         @user = create :user, first_name: 'Alan', last_name: 'Brown'
         @old_api_key = @user.api_key
         @user.new_api_key
         @user.save
      end
      should 'have an api key' do
        assert_not_nil User.find(@user.id).api_key
        assert_not_equal User.find(@user.id).api_key, @old_api_key
      end
    end

    context 'workflow' do
      should 'have "Next-gen sequencing" workflow set' do
        assert_not_nil(User.create!(login: 'foo').workflow, 'workflow has not been defaulted')
      end

      should 'not override the user choice' do
        workflow = create(:submission_workflow)
        assert_equal(workflow, User.create!(login: 'foo', workflow: workflow).workflow, 'workflow differs from what was requested')
      end
    end

    context 'without a swipecard_code' do
      setup do
        @user = create :user
      end

      should 'not have a swipecard code' do
        assert_equal false, @user.swipecard_code?
      end

      should 'be able to have one assigned' do
        code = 'code'
        @user.swipecard_code = code
      end
    end

    context 'is a data_access_coordinator' do
      setup do
        @user = create :data_access_coordinator
      end

      should 'be able to access data_access_coordinator functions' do
        assert @user.data_access_coordinator?
      end
    end
  end
end
