#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
require "test_helper"

class Pipelines::AssetsController ; def rescue_action(e) raise e end ; end

class Pipelines::AssetsControllerTest < ActionController::TestCase
  context 'Pipelines::AssetsController' do
    should_route(:get, '/pipelines/assets/new/1', :action => 'new', :id => '1')
    should_require_login(:new)

    context 'GET "new"' do
      setup do
        @controller.stubs(:current_user).returns(Factory(:user))

        @family = Factory(:family)
        get :new, :id => 123, :family => @family.id
      end

      should_render_without_layout

      should 'render a hidden field with the family id' do
        assert_select 'input[type=hidden][value=?]', @family.id
      end

      should 'render a removal link' do
        assert_select 'a[onclick="removeAsset(123);return false;"]'
      end
    end
  end
end
