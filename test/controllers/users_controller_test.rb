# frozen_string_literal: true

require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  context 'Users controller' do
    setup do
      @controller = UsersController.new
      @request = ActionController::TestRequest.create(@controller)
      LabelPrinter::PmbClient.stubs(:get_label_template_by_name).returns('data' => [{ 'id' => 15 }])
    end

    should_require_login :edit, :show, :update, resource: 'user'

    # should only be able to see your own page
  end
end
