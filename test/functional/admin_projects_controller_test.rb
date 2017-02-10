# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

require 'test_helper'
require 'admin/projects_controller'

class Admin::ProjectsControllerTest < ActionController::TestCase
  attr_reader :emails

  context 'Projects controller' do
    setup do
      @controller = Admin::ProjectsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context 'management UI' do
      setup do
        @user     = create :admin, email: 'project.owner@example.com'
        @project  = create :project, approved: false
        role = FactoryGirl.create :owner_role, authorizable: @project
        role.users << @user
        @request_type = FactoryGirl.create :request_type
        @other_request_type = FactoryGirl.create :request_type
        session[:user] = @user.id
        @emails = ActionMailer::Base.deliveries
        @emails.clear
      end

      context '#managed_update (without changes)' do
        setup do
          put :managed_update, id: @project.id, project: { name: @project.name }
        end

        should 'not send an email' do
          assert_equal [], emails
        end

        should redirect_to('admin projects') { "/admin/projects/#{@project.id}" }
      end

      context '#managed_update (with getting approved)' do
        setup do
          @event_count = Event.count
          put :managed_update, id: @project.id, project: { approved: true, name: @project.name }
        end

        should redirect_to('admin project') { "/admin/projects/#{@project.id}" }
        should set_flash.to('Your project has been updated')

        should 'change Event.count by 1' do
          assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
        end

        should 'send an email' do
          assert_equal 1, emails.count
          assert_match "Project #{@project.id}: Project approved\n\nProject approved by #{@user.login}", emails.first.parts.first.body.to_s
        end

        should 'Have sent an email' do
          last_mail = ActionMailer::Base.deliveries.last
          assert_match(/[TEST].*Project/, last_mail.subject)
          assert last_mail.bcc.include? 'project.owner@example.com'
          assert_match(/Project approved by/, last_mail.text_part.body.to_s)
        end
      end
    end
  end
end
