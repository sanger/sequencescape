# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

class Admin::ProgramsControllerTest < ActionController::TestCase
  context 'Admin Programs controller' do
    setup do
      @controller = Admin::ProgramsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
      session[:user] = @user = create :admin
    end

    should_require_login

    context '#create' do
      setup do
        FactoryGirl.create :program, name: 'My unique name of program'
      end

      should 'create a new program' do
        num = Program.count
        post :create, program: { name: 'A very new program name' }
        assert_equal num + 1, Program.count
        assert assigns(:program)
        assert_redirected_to admin_program_path(assigns(:program))
      end

      should 'not create a new program with same name as a previous program' do
        num = Program.count
        post :create, program: { name: 'My unique name of program' }
        assert_equal num, Program.count
      end
    end

    context '#edit' do
      setup do
        @program = FactoryGirl.create :program, name: 'My program name'
      end

      should 'edit the name of the new program' do
        post :update, id: @program.id, program: { name: 'A new name for the program' }

        assert_equal true, Program.find_by(name: 'My program name').nil?
        assert_equal false, Program.find_by(name: 'A new name for the program').nil?
        assert_equal @program.id, Program.find_by(name: 'A new name for the program').id
      end
    end

    context '#show' do
      setup do
        @program = create :program
      end

      should 'display existing programs' do
        get :show, id: @program.id
        assert_equal @program, assigns(:program)
      end
    end
  end
end
