require "test_helper"


class EventFactoryTest < ActiveSupport::TestCase
  context "An EventFactory" do
    setup do
      @user = Factory :user, :login => "south", :email => "south@example.com"
      @project = Factory :project, :name => "hello world"
      #@project = Factory :project, :name => "hello world", :user => @user
      role = Factory :owner_role, :authorizable => @project
      role.users << @user
      @request_type = Factory :request_type, :key => "library_creation", :name => "Library creation"
      @request = Factory :request, :request_type => @request_type, :user => @user, :project => @project
    end

    context "#request increase in quota" do
      setup do
        admin = Factory :role, :name => "administrator"
        user1 = Factory :user, :login => "bla"
        user2 = Factory :user, :login => "wow"
        user2.roles << admin
        user1.roles << admin
        comment = "New comment"
        @incoming = {:library_creation => 20}
        EventFactory.quota_update(@project, @user, @incoming, comment)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should "include proper message and content" do
        assert_equal "Quota update request", Event.last.message
        assert Event.last.content =~ /An increase in #{@request_type.name.downcase} quota: from 0 to #{@incoming[:library_creation]}/
      end

      should "send an email" do
        assert_sent_email do |email|
          email.subject =~ /Project/ &&  email.subject =~ /[TEST]/ && email.bcc.include?("bla@example.com")
          email.bcc.size == 2
          email.body    =~ /An increase in #{@request_type.name.downcase} quota: from 0 to #{@incoming[:library_creation]}/
        end
      end
    end

    context "#quota updated" do
      setup do
        admin = Factory :role, :name => "administrator"
        user1 = Factory :user, :login => "abc123"
        user1.roles << admin
        EventFactory.quota_updated(@project, @user)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should "sends 2 emails to 2 recipient" do
        assert_sent_email do |email|
          email.subject =~ /Project quota approved/ \
            && email.bcc.include?("abc123@example.com") \
            && email.bcc.include?("south@example.com") \
            && email.bcc.size == 2 \
            && email.body =~ /Project quota approved by #{@user.login}/
        end
      end
    end

    context "#new_project" do
      setup do
        admin = Factory :role, :name => "administrator"
        user1 = Factory :user, :login => "abc123"
        user1.roles << admin
        EventFactory.new_project(@project, @user)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should "send 1 email to 1 recipient" do
        assert_sent_email do |email|
          email.subject =~ /Project/ \
            && email.bcc.include?("abc123@example.com") \
            && email.bcc.size == 1 \
            && email.body =~ /Project registered/
        end
      end
    end

    context "#new_sample" do
      setup do
        admin = Factory :role, :name => "administrator"
        user1 = Factory :user, :login => "abc123"
        user1.roles << admin
        @sample = Factory :sample, :name => "NewSample"
      end

      context "project is blank" do
        setup do
          EventFactory.new_sample(@sample, [], @user)
        end

        should_change("Event.count", :by => 1) { Event.count }

        should "send an email to one recipient" do
          assert_sent_email do |email|
            email.subject =~ /Sample/ \
              && email.bcc.include?("abc123@example.com") \
              && email.bcc.size == 1 \
              && email.body =~ /New '#{@sample.name}' registered by #{@user.login}/
          end
        end
      end

      context "project is not blank" do
        setup do
          EventFactory.new_sample(@sample, @project, @user)
        end

        should_change("Event.count", :by => 2) { Event.count }

        should "send 2 emails each to one recipient" do
          assert_sent_email do |email|
            email.subject =~ /Sample/ \
              && email.bcc.include?("abc123@example.com") \
              && email.bcc.size == 1 \
              && email.body =~ /New '#{@sample.name}' registered by #{@user.login}/
          end

          assert_sent_email do |email|
            email.subject =~ /Project/ \
              && email.bcc.include?("abc123@example.com") \
              && email.bcc.size == 1 \
              && email.body =~ /New '#{@sample.name}' registered by #{@user.login}: #{@sample.name}. This sample was assigned to the '#{@project.name}' project./
          end
        end
      end
    end

    context "#project_approved" do
      setup do
        ::ActionMailer::Base.deliveries = [] # reset the queue
        role = Factory :manager_role, :authorizable => @project
        role.users << @user
        admin = Factory :role, :name => "administrator"
        user1 = Factory :user, :login => "west"
        user1.roles << admin
        EventFactory.project_approved(@project, @user)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should "send email to project manager" do
        assert_sent_email do |email|
          email.subject =~ /Project/ \
            && email.subject =~ /Project approved/ \
            && email.bcc.include?("#{@user.login}@example.com") \
            && email.bcc.size == 1 \
            && email.body =~ /Project approved/
        end
      end
    end

    context "#project_approved by administrator" do
      setup do
        ::ActionMailer::Base.deliveries = [] # reset the queue
        admin = Factory :role, :name => "administrator"
        @user1 = Factory :user, :login => "west"
        @user1.roles << admin
        @user2 = Factory :user, :login => "north"
        @user2.roles << admin
        role = Factory :manager_role, :authorizable => @project
        role.users << @user
        EventFactory.project_approved(@project, @user2)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should ": send emails to the (two) administrators" do
        assert_sent_email do |email|
          email.subject =~ /Project/ \
            && email.subject =~ /Project approved/ \
            && email.bcc.include?("#{@user1.login}@example.com") \
            && email.bcc.size == 1 \
            && email.body =~ /Project approved/
        end
        assert_sent_email do |email|
          email.subject =~ /Project/ \
            && email.subject =~ /Project approved/ \
            && email.bcc.include?("#{@user2.login}@example.com") \
            && email.bcc.size == 1 \
            && email.body =~ /Project approved/
        end
      end

      should ": send email to project manager" do
        assert_sent_email do |email|
          email.subject =~ /Project/ \
            && email.subject =~ /Project approved/ \
            && email.bcc.include?("#{@user.login}@example.com") \
            && email.bcc.size == 1 \
            && email.body =~ /Project approved/
        end
      end
    end

    context "#project_approved but not by administrator" do
      setup do
        ::ActionMailer::Base.deliveries = []
        admin = Factory :role, :name => "administrator"
        @user1 = Factory :user, :login => "west"
        @user1.roles << admin
        follower = Factory :role, :name => "follower"
        @user2 = Factory :user, :login => "north"
        @user2.roles << follower
        role = Factory :manager_role, :authorizable => @project
        role.users << @user
        EventFactory.project_approved(@project, @user2)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should ": send email to project manager" do
        assert_sent_email do |email|
          email.subject =~ /Project/ \
            && email.subject =~ /Project approved/ \
            && email.bcc.include?("#{@user.login}@example.com") \
            && email.bcc.size == 1 \
            && email.body =~ /Project approved/
        end
      end

      should "send no email to adminstrator nor to approver" do
        assert_did_not_send_email { |email| "#{email.bcc}" ==  "#{@user1.login}@example.com" }
        assert_did_not_send_email { |email| "#{email.bcc}" ==  "#{@user2.login}@example.com" }
      end
    end

    context "#study has samples added" do
      setup do
        ::ActionMailer::Base.deliveries = []
        role = Factory :manager_role, :authorizable => @project
        role.users << @user
        follower = Factory :role, :name => "follower"
        @user1 = Factory :user, :login => "north"
        @user1.roles << follower
        @user2 = Factory :user, :login => "west"
        @user2.roles << follower
        @study = Factory :study, :user => @user2
        @submission = Factory::submission :project => @project, :study => @study, :asset_group_name => 'to prevent asset errors'
        @samples = []
        @samples[0] = Factory :sample, :name => "NewSample-1"
        @samples[1] = Factory :sample, :name => "NewSample-2"
        EventFactory.study_has_samples_registered(@study, @samples, @user1)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should "send email to project manager" do
        assert_sent_email do |email|
          email.subject =~ /Sample/ \
            && email.subject =~ /registered/ \
            && email.bcc \
            && email.bcc.include?("#{@user.email}") \
            && email.bcc.size == 1
        end
      end

    end

    context "#request update failed" do
      setup do
        ::ActionMailer::Base.deliveries = []
        role = Factory :manager_role, :authorizable => @project
        role.users << @user
        @user1 = Factory :user, :login => "north"
        @request.user = @user1
        follower = Factory :role, :name => "follower"
        @user2 = Factory :user, :login => "west"
        @user2.roles << follower
        @study = Factory :study, :user => @user2
        @submission = Factory::submission :project => @project, :study => @study, :assets => [Factory :sample_tube]
        @request = Factory :request, :study => @study, :project => @project,  :submission => @submission
        @user3 = Factory :user, :login => "east"
        message = "An error has occurred"
        EventFactory.request_update_note_to_manager(@request, @user3, message)
      end

      should_change("Event.count", :by => 1) { Event.count }

      should "send email to project manager" do
        assert_sent_email do |email|
          email.subject =~ /Request update/ \
            && email.subject =~ /failed/ \
            && email.bcc \
            && email.bcc.include?("#{@user.email}") \
            && email.bcc.size == 1
        end
      end
    end
  end

  def assert_did_not_send_email
# invocation with block tests absence of a specific email
    if block_given?
      emails = ::ActionMailer::Base.deliveries
      matching_emails = emails.select do |email|
        yield email
      end
      assert matching_emails.empty?
    else
# invocation without block lists any mails in the queue for test
# e.g. use as: 'should "list" do  assert_did_not_send_mail; end'
      msg = "Sent #{::ActionMailer::Base.deliveries.size} emails.\n"
      ::ActionMailer::Base.deliveries.each do |email|
        msg << "  ‘#{email.subject}’ sent to #{email.bcc}:\n#{email.body}\n\n"
      end
      assert ::ActionMailer::Base.deliveries.empty?, msg
    end
  end

end
