# frozen_string_literal: true

require 'test_helper'

module Admin
  class ProgramsControllerTest < ActionController::TestCase
    context 'Admin Programs controller' do
      setup do
        @controller = Admin::ProgramsController.new
        @request = ActionController::TestRequest.create(@controller)
        session[:user] = @user = create(:admin)
      end

      should_require_login

      context '#create' do
        setup { FactoryBot.create(:program, name: 'My unique name of program') }

        should 'create a new program' do
          num = Program.count
          post :create, params: { program: { name: 'A very new program name' } }

          assert_equal num + 1, Program.count
          assert assigns(:program)
          assert_redirected_to admin_program_path(assigns(:program))
        end

        should 'not create a new program with same name as a previous program' do
          num = Program.count
          post :create, params: { program: { name: 'My unique name of program' } }

          assert_equal num, Program.count
        end
      end

      context '#edit' do
        setup { @program = FactoryBot.create(:program, name: 'My program name') }

        should 'edit the name of the new program' do
          post :update, params: { id: @program.id, program: { name: 'A new name for the program' } }

          assert_equal true, Program.find_by(name: 'My program name').nil?
          assert_equal false, Program.find_by(name: 'A new name for the program').nil?
          assert_equal @program.id, Program.find_by(name: 'A new name for the program').id
        end
      end

      context '#show' do
        setup { @program = create(:program) }

        should 'display existing programs' do
          get :show, params: { id: @program.id }

          assert_equal @program, assigns(:program)
        end
      end
    end
  end
end
