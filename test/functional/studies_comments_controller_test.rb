#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"

# Re-raise errors caught by the controller.
class Studies::CommentsController; def rescue_action(e) raise e end; end

class Studies::CommentsControllerTest < ActionController::TestCase
  context "Studies controller" do
    setup do
      @controller = Studies::CommentsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should_require_login

    resource_test('comment', {:actions => ['index'], :ignore_actions => ["new", "edit", "update", "show", 'destroy', 'create'], :formats => ['html'], :parent => "study", :other_actions => ['add']})

  end
end
