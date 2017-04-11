# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

class Pipelines::AssetsControllerTest < ActionController::TestCase
  context 'Pipelines::AssetsController' do
    setup do
      @controller = Pipelines::AssetsController.new
      @request    = ActionController::TestRequest.new
      @response   = ActionController::TestResponse.new
    end

    should route(:get, '/pipelines/assets/new/1').to(action: 'new', id: '1')
    should_require_login(:new)

    context 'GET "new"' do
      setup do
        session[:user] = create(:user)

        @family = create(:family)
        get :new, id: 123, family: @family.id
      end

      should_not render_with_layout

      should 'find the family' do
        assert_equal assigns(:family), @family
      end

      should 'create a new asset' do
        assert assigns(:asset).is_a?(Asset)
      end

      should 'render a removal link' do
        # This is really not ideal, but I couldn't work out why assert_select only found text nodes in the second td.
        # Its possibly a strict validator hating on the onClick. Understandable, but not ready to tidy up the legacy
        # code JUST yet.
        assert_includes @response.body, 'onClick="removeAsset(123);return false;"'
      end
    end
  end
end
