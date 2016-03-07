#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"

# Re-raise errors caught by the controller.
class Studies::EventsController; def rescue_action(e) raise e end; end

class Studies::EventsControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Studies::EventsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new

      @user     =FactoryGirl.create :user
      @controller.stubs(:current_user).returns(@user)
      @study  =FactoryGirl.create :study
    end

    should_require_login(:index)

     context "#index" do
        setup do
          @controller.stubs(:current_user).returns(create(:user))
          get :index, :study_id => @study.id
        end
        should respond_with :success
        should render_template :index
      end
  end
end
