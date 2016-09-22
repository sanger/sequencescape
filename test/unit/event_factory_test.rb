#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

require "test_helper"


class EventFactoryTest < ActiveSupport::TestCase

  attr_reader :emails

  context "An EventFactory" do
    setup do
      @user = create :user, :login => "south", :email => "south@example.com"
      @bad_user = create :user, :login => "south", :email => ""
      @project = create :project, :name => "hello world"
      #@project = create :project, :name => "hello world", :user => @user
      role = create :owner_role, :authorizable => @project
      role.users << @user << @bad_user
      @request_type = create :request_type, :key => "library_creation", :name => "Library creation"
      @request = create :request, :request_type => @request_type, :user => @user, :project => @project
      @emails = ActionMailer::Base.deliveries
      @emails.clear
    end

    context "#new_project" do
      setup do
        @event_count =  Event.count
        admin = create :role, :name => "administrator"
        user1 = create :user, :login => "abc123"
        user1.roles << admin
        EventFactory.new_project(@project, @user)
      end

      should "change Event.count by 1" do
        assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

      context "send 1 email to 1 recipient" do

        should "send email" do
          assert_equal 1, emails.count
          assert_match "Project #{@project.id}: Project registered\n\nProject registered by south", emails.first.parts.first.body.to_s
        end

        should have_sent_email.
          with_subject(/Project/).
          bcc("abc123@example.com").
          with_body(/Project registered/)
        # should have_sent_email.bcc.size == 1
        should_not have_sent_email.bcc("")
      end
    end

    context "#new_sample" do
      setup do
        @event_count =  Event.count
        admin = create :role, :name => "administrator"
        user1 = create :user, :login => "abc123"
        user1.roles << admin
        @sample = create(:sample, :name => "NewSample")
      end

      context "project is blank" do
        setup do
          EventFactory.new_sample(@sample, [], @user)
        end

       should "change Event.count by 1" do
         assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

        context "send an email to one recipient" do
          should have_sent_email.
            with_subject(/Sample/).
            bcc("abc123@example.com").
            with_body(/registered by south/)
        end
      end

      context "project is not blank" do
        setup do
          @event_count =  Event.count
          EventFactory.new_sample(@sample, @project, @user)
        end


        should "change Event.count by 2" do
          assert_equal 2,  Event.count  - @event_count, "Expected Event.count to change by 2"
        end

        should "send email" do
          assert_equal 1, emails.count
          assert_match "New 'NewSample' registered by south: NewSample. This sample was assigned to the 'hello world' project.", HTMLEntities.new.decode(emails.first.parts.first.body.to_s)
        end

        context "send 2 emails each to one recipient" do
          should have_sent_email.
            with_subject(/Sample/).
            bcc("abc123@example.com").
            # && email.bcc.size == 1 \
            with_body(/registered by south/)


          should have_sent_email.
            with_subject(/Project/).
            bcc("abc123@example.com").
            # && email.bcc.size == 1 \
            with_body(/This sample was assigned/)

          should_not have_sent_email.bcc("")
        end
      end
    end

    context "#project_approved" do
      setup do
        @event_count =  Event.count
        # ::ActionMailer::Base.deliveries = [] # reset the queue
        role = create :manager_role, :authorizable => @project
        role.users << @user
        admin = create :role, :name => "administrator"
        user1 = create :user, :login => "west"
        user1.roles << admin
        EventFactory.project_approved(@project, @user)
      end

      should "change Event.count by 1" do
        assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

      should "send email" do
        assert_equal 1, emails.count
        assert_match "Project approved\n\nProject approved by south", emails.first.parts.first.body.to_s
      end

      context "send email to project manager" do
        should have_sent_email.
          with_subject(/Project approved/).
          bcc("south@example.com").
          with_body(/Project approved/)

        should_not have_sent_email.bcc("")
      end
    end

    context "#project_approved by administrator" do
      setup do
        @event_count =  Event.count
        ::ActionMailer::Base.deliveries = [] # reset the queue
        admin = create :role, :name => "administrator"
        @user1 = create :user, :login => "west"
        @user1.roles << admin
        @user2 = create :user, :login => "north"
        @user2.roles << admin
        role = create :manager_role, :authorizable => @project
        role.users << @user
        EventFactory.project_approved(@project, @user2)
      end

      should "change Event.count by 1" do
        assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

      context ": send emails to everyone administrators" do
        should have_sent_email.
          with_subject(/Project approved/).
          bcc("west@example.com").
          bcc("north@example.com").
          bcc("south@example.com").
          with_body(/Project approved/)

        should_not have_sent_email.bcc("")
      end

    end

    context "#project_approved but not by administrator" do
      setup do
        @event_count =  Event.count
        ::ActionMailer::Base.deliveries = []
        admin = create :role, :name => "administrator"
        @user1 = create :user, :login => "west"
        @user1.roles << admin
        follower = create :role, :name => "follower"
        @user2 = create :user, :login => "north"
        @user2.roles << follower
        role = create :manager_role, :authorizable => @project
        role.users << @user
        EventFactory.project_approved(@project, @user2)
      end


      should "change Event.count by 1" do
        assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

      context ": send email to project manager" do
        should have_sent_email.
          with_subject(/Project/).
          with_subject(/Project approved/).
          bcc("south@example.com").
          with_body(/Project approved/)

      should_not have_sent_email.bcc("")
      end

      context "send no email to adminstrator nor to approver" do
        should_not have_sent_email.bcc("west@example.com")
        should_not have_sent_email.bcc("north@example.com")
        should_not have_sent_email.bcc("")
      end
    end

    context "#study has samples added" do
      setup do
        @event_count =  Event.count
        ::ActionMailer::Base.deliveries = []
        role = create :manager_role, :authorizable => @project
        role.users << @user
        follower = create :role, :name => "follower"
        @user1 = create :user, :login => "north"
        @user1.roles << follower
        @user2 = create :user, :login => "west"
        @user2.roles << follower
        @study = create :study, :user => @user2
        @submission = FactoryHelp::submission :project => @project, :study => @study, :asset_group_name => 'to prevent asset errors'
        @samples = []
        @samples[0] = create :sample, :name => "NewSample-1"
        @samples[1] = create :sample, :name => "NewSample-2"
        EventFactory.study_has_samples_registered(@study, @samples, @user1)
      end

       should "change Event.count by 1" do
         assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

      context "send email to project manager" do
        should have_sent_email.
          with_subject(/Sample/).
          with_subject(/registered/).
          bcc("south@example.com")
      end

    end

    context "#request update failed" do
      setup do
        @event_count =  Event.count
        ::ActionMailer::Base.deliveries = []
        role = create :manager_role, :authorizable => @project
        role.users << @user
        @user1 = create :user, :login => "north"
        @request.user = @user1
        follower = create :role, :name => "follower"
        @user2 = create :user, :login => "west"
        @user2.roles << follower
        @study = create :study, :user => @user2
        @submission = FactoryHelp::submission(:project => @project, :study => @study, :assets => [create(:sample_tube)])
        @request = create :request, :study => @study, :project => @project,  :submission => @submission
        @user3 = create :user, :login => "east"
        message = "An error has occurred"
        EventFactory.request_update_note_to_manager(@request, @user3, message)
      end


       should "change Event.count by 1" do
         assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
      end

      context "send email to project manager" do
        should have_sent_email.
          with_subject(/Request update/).
          with_subject(/failed/).
          bcc("south@example.com")
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
        msg << "  '#{email.subject}' sent to #{email.bcc}:\n#{email.body}\n\n"
      end
      assert ::ActionMailer::Base.deliveries.empty?, msg
    end
  end

end
