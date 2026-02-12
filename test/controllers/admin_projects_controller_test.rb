# frozen_string_literal: true

require 'test_helper'

module Admin
  class ProjectsControllerTest < ActionController::TestCase
    attr_reader :emails

    context 'Projects controller' do
      setup do
        @controller = Admin::ProjectsController.new
        @request = ActionController::TestRequest.create(@controller)
      end

      should_require_login

      context 'management UI' do
        setup do
          @user = create(:admin, email: 'project.owner@example.com')
          @project = create(:project, approved: false)
          role = FactoryBot.create(:owner_role, authorizable: @project)
          role.users << @user
          @request_type = FactoryBot.create(:request_type)
          @other_request_type = FactoryBot.create(:request_type)
          session[:user] = @user.id
          @emails = ActionMailer::Base.deliveries
          @emails.clear
        end

        context '#managed_update (without changes)' do
          setup { put :managed_update, params: { id: @project.id, project: { name: @project.name } } }

          should 'not send an email' do
            assert_empty emails
          end

          should redirect_to('admin projects') { "/admin/projects/#{@project.id}" }
        end

        context '#managed_update (with getting approved)' do
          setup do
            @event_count = Event.count
            put :managed_update, params: { id: @project.id, project: { approved: true, name: @project.name } }
          end

          should redirect_to('admin project') { "/admin/projects/#{@project.id}" }
          should set_flash.to('Your project has been updated')

          should 'change Event.count by 1' do
            assert_equal 1, Event.count - @event_count, 'Expected Event.count to change by 1'
          end

          # History: Projects had to be approved post creation. Now approval is done pre generation.
          # Therefore function not required
          should 'not send email any more' do
            assert_equal 0, emails.count
          end
        end
      end
    end
  end
end
