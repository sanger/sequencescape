require "test_helper"

class UserTest < ActiveSupport::TestCase
  context "A User" do
if false
    should_have_many :items
    should_have_many :requests
    should_have_many :comments
    should_have_and_belong_to_many :roles

    context "authenticate" do
      setup do
          @user = Factory :admin, :login => 'xyz987', :api_key => 'my_key', :crypted_password => '1'
          @ldap = mock("LDAP")
          @ldap.stubs(:bind).returns(true)
          Net::LDAP.stubs(:new).returns(@ldap)

          @response = mock("Response")
          @response.stubs(:body).returns('{"valid":1,"username":"xyz987"}')
          Net::HTTP.stubs(:post_form).returns(@response)
      end

      should "login_in_user" do
        assert_equal true, User.authenticate_with_ldap("someone","password")
      end

      should_eventually "work_with_sanger_sso" do
        http = mock("http")
        http.stubs(:read).returns("xyz987")
        OpenURI.stubs(:open_uri).returns(http)
        user =  User.authenticate_by_sanger_cookie("cookie_string")
        assert_instance_of String, user
        assert_equal "xyz987", user
      end
    end

    context "is an administrator" do
      setup do
        @user = Factory :admin
      end

      should "be able to access admin functions" do
        assert @user.administrator?
      end

      should "be able to access manager functions" do
        assert @user.manager_or_administrator?
      end

      should "have access to privileged functions" do
        assert @user.privileged?
      end

      # should "have access to privileged functions (when not owner)" do
      #   @owner = Factory :user
      #   @sample = Factory :sample, :user => @owner
      #   assert @user.privileged?(@sample)
      # end
    end

    context "is a manager" do
      setup do
        @user = Factory :manager
      end

      should "not be able to access admin functions" do
        assert ! @user.administrator?
      end

      should "be able to access manager functions" do
        assert @user.manager_or_administrator?
      end

      should "have be manager" do
        assert @user.manager?
      end

      should "have access to privileged functions" do
        assert @user.privileged?
      end

      # should "have access to privileged functions (when not owner)" do
      #   @owner = Factory :user
      #   @sample = Factory :sample, :user => @owner
      #   assert @user.privileged?(@sample)
      # end
    end

    context "is an owner" do
      setup do
        @user = Factory :owner
      end

      should "not be able to access admin functions" do
        assert ! @user.administrator?
      end

      should "not be able to access manager functions" do
        assert ! @user.manager_or_administrator?
      end

      should "not have access to privileged functions generally" do
        assert ! @user.privileged?
      end

      # should "not have access to privileged functions when not owner" do
      #   @owner = Factory :user
      #   @sample = Factory :sample, :user => @owner
      #   assert ! @user.privileged?(@sample)
      # end

      # should "have access to privileged functions when owner" do
      #   @sample = Factory :sample, :user => @user
      #   assert @user.privileged?(@sample)
      # end
    end


    context "admins and emails" do
      setup do
        admin = Factory :role, :name => "administrator"
        user1 = Factory :user, :login => "bla"
        user2 = Factory :user, :login => "wow"
        user2.roles << admin
        user1.roles << admin
      end

      should "return all admins and associated email addresses" do
        assert_equal 2, User.all_administrators.size
        assert_equal 2, User.all_administrators_emails.size
        assert_equal true, User.all_administrators_emails.include?("wow@example.com")
        assert_equal true, User.all_administrators_emails.include?("bla@example.com")
      end
    end

    context "#name" do
      context "when profile is complete" do
        setup do
          @user = Factory :user, :first_name => "Alan", :last_name => "Brown"
          assert @user.valid?
        end
        should "return full name" do
          assert_equal "Alan Brown", @user.name
        end
      end
      context "when profile is incomplete" do
        setup do
          @user = Factory :user, :login => "abc123", :first_name => "Alan", :last_name => nil
          assert @user.valid?
        end
        should "return login" do
          assert_equal "abc123", @user.name
        end
      end
    end

    context "#new_api_key" do
      setup do
         @user = Factory :user, :first_name => "Alan", :last_name => "Brown"
         @old_api_key = @user.api_key
         @user.new_api_key
         @user.save
      end
      should "have an api key" do
        assert_not_nil User.find(@user.id).api_key
        assert_not_equal User.find(@user.id).api_key, @old_api_key
      end
    end
    context "#profile_complete? with no api_key" do
      setup do
        @user = Factory :user, :first_name => "Alan", :last_name => "Brown", :email => "ab1",:api_key => nil
        @old_api_key = @user.api_key
        @profile_complete = @user.profile_complete?
      end
      should "generate an api_key" do
        assert_not_nil User.find(@user.id).api_key
        assert_not_equal User.find(@user.id).api_key, @old_api_key
        assert @profile_complete
      end
    end
    context "#profile_complete? with preexisting api_key" do
      setup do
        @user = Factory :user, :first_name => "Alan", :last_name => "Brown", :email => "ab1",:api_key => 'da57c7a7e600b-2736f3329f3d99cdb2e52d4f184f39f1'
        @old_api_key = @user.api_key
        @profile_complete = @user.profile_complete?
      end
      should "generate an api_key" do
        assert_equal User.find(@user.id).api_key, @old_api_key
        assert @profile_complete
      end
    end


end

  context 'workflow' do
    should 'have "Next-gen sequencing" workflow set' do
      assert_not_nil(User.create!(:login => 'foo').workflow, 'workflow has not been defaulted')
    end

    should 'not override the user choice' do
      workflow = Factory(:submission_workflow)
      assert_equal(workflow, User.create!(:login => 'foo', :workflow => workflow).workflow, 'workflow differs from what was requested')
    end
  end

    context "without a swipecard_code" do
      setup do
        @user = Factory :user
      end

      should "not have a swipecard code" do
        assert_equal false, @user.swipecard_code?
      end
      should "be able to have one assigned" do
        code = "code"
        @user.swipecard_code=code
      end
    end

    context '#authenticate_by_sanger_cookie' do
      should 'use the user from the database if they have logged in recently' do
        user = User.create!(:login => 'john', :cookie => '123456789', :cookie_validated_at => 5.minutes.ago)
        assert_equal(user.id, User.authenticate_by_sanger_cookie('123456789').id)
      end

      should 'request the user information from the service if they have not logged in recently' do
        validated_at = (configatron.sanger_auth_freshness + 5).minutes.ago
        user = User.create!(:login => 'john', :cookie => '123456789', :cookie_validated_at => validated_at)
        User.expects(:user_from_single_sign_on_service).returns(user)

        User.authenticate_by_sanger_cookie('123456789')
        assert(validated_at < user.cookie_validated_at, 'User appears to have not been revalidated')
      end

      should 'request the user information from the service based on the cookie' do
        user = User.new(:login => 'john')
        User.expects(:user_from_single_sign_on_service).returns(user)

        User.authenticate_by_sanger_cookie('123456789')
        assert_not_nil(user.cookie_validated_at, 'User appears to have not been validated')
      end

      should 'not blow up if the user cannot be identified by the service' do
        User.expects(:user_from_single_sign_on_service).returns(nil)
        User.authenticate_by_sanger_cookie('123456789')
      end
    end
  end
end
