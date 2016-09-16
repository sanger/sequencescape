#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2012,2013,2015 Genome Research Ltd.

require "test_helper"
require 'samples_controller'

# Re-raise errors caught by the controller.
class Admin::ProjectsController; def rescue_action(e) raise e end; end

class Admin::ProjectsControllerTest < ActionController::TestCase

  attr_reader :emails

  context "Projects controller" do
    setup do
      @controller = Admin::ProjectsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    context "management UI" do
      setup do
        @user     =FactoryGirl.create :admin, :email => "project.owner@example.com"
        @project  =FactoryGirl.create :project, :approved => false
        role =FactoryGirl.create :owner_role, :authorizable => @project
        role.users << @user
        @request_type =FactoryGirl.create :request_type
        @other_request_type =FactoryGirl.create :request_type
        @controller.stubs(:current_user).returns(@user)
        @controller.stubs(:logged_in?).returns(@user)
        @emails = ActionMailer::Base.deliveries
        @emails.clear
      end

      context "#managed_update (without changes)" do
        setup do
          get :managed_update, :id => @project.id, :project => { :name => @project.name }
        end

        should "not send an email" do
          assert_equal [], emails
        end

        should redirect_to("admin projects") { "/admin/projects/#{@project.id}" }
      end


      context "#managed_update (with getting approved)" do
        setup do
          @event_count =  Event.count
          get :managed_update, :id => @project.id, :project => { :approved => true, :name => @project.name }
        end

        should redirect_to("admin project") { "/admin/projects/#{@project.id}" }
        should set_the_flash.to("Your project has been updated")


        should "change Event.count by 1" do
          assert_equal 1,  Event.count  - @event_count, "Expected Event.count to change by 1"
        end

        should "send an email" do
          assert_equal 1, emails.count
          assert_match "Project #{@project.id}: Project approved\n\nProject approved by abc123", emails.first.parts.first.body.to_s
        end



        should have_sent_email.
          with_subject(/[TEST].*Project/).
          bcc("project.owner@example.com").
          with_body(/Project approved by/)
          # email.bcc.size  == 2
      end
    end


  end
end
