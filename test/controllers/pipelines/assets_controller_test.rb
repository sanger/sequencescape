require 'test_helper'

module Pipelines
  class AssetsControllerTest < ActionController::TestCase
    context 'Pipelines::AssetsController' do
      setup do
        @controller = Pipelines::AssetsController.new
        @request    = ActionController::TestRequest.create(@controller)
      end

      should route(:get, '/pipelines/assets/new/1').to(action: 'new', id: '1')
      should_require_login(:new, resource: 'asset', parent: 'pipeline')

      context 'GET "new"' do
        setup do
          session[:user] = create(:user)

          @family = create(:family)
          get :new, params: { id: 123, family: @family.id }
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
end
