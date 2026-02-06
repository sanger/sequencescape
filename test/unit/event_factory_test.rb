# frozen_string_literal: true

require 'test_helper'

class EventFactoryTest < ActiveSupport::TestCase
  attr_reader :emails

  context 'An EventFactory' do
    setup do
      @user = create(:user, login: 'south', email: 'south@example.com')
      @bad_user = create(:user, login: 'bad_south', email: '')
      @project = create(:project, name: 'hello world')
      role = create(:owner_role, authorizable: @project)
      role.users << @user << @bad_user
      @request_type = create(:request_type, key: 'library_creation', name: 'Library creation')
      @request = create(:request, request_type: @request_type, user: @user, project: @project)
      @emails = ActionMailer::Base.deliveries
      @emails.clear
      @labware = create(:sample_tube, retention_instruction: 'return_to_customer_after_2_years')
    end

    context '#new_project' do
      setup do
        @event_count = Event.count
        admin = create(:role, name: 'administrator')
        user1 = create(:user, login: 'abc123')
        user1.roles << admin
        EventFactory.new_project(@project, @user)
      end

      should 'change Event.count by 1' do
        assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
      end

      # History: Projects had to be approved post creation. Now approval is done pre generation.
      # Therefore function not required
      should 'not send email any more' do
        assert_equal 0, emails.count
      end
    end

    context '#project_approved' do
      setup do
        @event_count = Event.count
        role = create(:manager_role, authorizable: @project)
        role.users << @user
        admin = create(:role, name: 'administrator')
        user1 = create(:user, login: 'west')
        user1.roles << admin
        EventFactory.project_approved(@project, @user)
      end

      # History: Projects had to be approved post creation. Now approval is done pre generation.
      # Therefore function not required
      should 'not send email any more' do
        assert_equal 0, emails.count
      end

      should 'change Event.count by 1' do
        assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
      end
    end

    context '#request update failed' do
      setup do
        @event_count = Event.count
        ::ActionMailer::Base.deliveries = []
        role = create(:manager_role, authorizable: @project)
        role.users << @user
        @user1 = create(:user, login: 'north')
        @request.user = @user1
        follower = create(:role, name: 'follower')
        @user2 = create(:user, login: 'west')
        @user2.roles << follower
        @study = create(:study, user: @user2)
        @submission = FactoryHelp.submission(project: @project, study: @study, assets: [create(:sample_tube)])
        @request = create(:request, study: @study, project: @project, submission: @submission)
        @user3 = create(:user, login: 'east')
        message = 'An error has occurred'
        EventFactory.request_update_note_to_manager(@request, @user3, message)
      end

      should 'change Event.count by 1' do
        assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
      end

      context 'send email to project manager' do
        should 'Have sent an email' do
          last_mail = ActionMailer::Base.deliveries.last

          assert_match(/Request update/, last_mail.subject)
          assert_match(/failed/, last_mail.subject)
          assert_includes last_mail.bcc, 'south@example.com'
        end
      end
    end

    context '#record_retention_instruction_updates' do
      setup do
        @event_count = Event.count
        @old_retention_instruction = @labware.retention_instruction
        @new_retention_instruction = 'destroy_after_2_years'
        EventFactory.record_retention_instruction_updates(@labware, @user, @old_retention_instruction)
      end

      should 'change Event.count by 1' do
        assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
      end
    end
  end
end
