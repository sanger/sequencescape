# frozen_string_literal: true

require File.join(File.dirname(__FILE__), 'sanger_macros', 'resource_test')

module Sanger
  module Testing
    module Controller
      module Macros
        def should_have_instance_methods(*methods)
          dt = described_type
          should "have instance methods #{methods.join(',')}" do
            methods.each { |method| assert_respond_to dt.new, method, "Missing instance methods #{method} on #{dt}" }
          end
        end

        # rubocop:todo Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/BlockLength
        def should_require_login(*actions) # rubocop:todo Metrics/CyclomaticComplexity, Metrics/AbcSize
          params = (actions.pop if actions.last.is_a?(Hash)) || {}
          actions << :index if actions.empty?
          actions.each do |action|
            context action.to_s do
              context 'when logged in' do
                setup do
                  session[:user] = create(:user)
                  begin
                    get(action, params:)
                  rescue AbstractController::ActionNotFound
                    flunk "Testing for an unknown action: #{action}"
                  rescue ActiveRecord::RecordNotFound
                    assert true
                  rescue ActionView::MissingTemplate
                    flunk "Missing template for #{action} action"
                  rescue StandardError
                    # The assumption below does not look right, as there also might be a problem with routes
                    # in case of nested resources, for example. Should we fix it?
                    # Assume any other problem is due to the controller not handling things
                    assert true
                  end
                end

                should 'not redirect' do
                  assert_not (300..307).to_a.include?(@response.code)
                end
              end
              context 'when not logged in' do
                setup do
                  session[:user] = nil
                  if params[:resource].present?
                    resource = params.delete(:resource)
                    params['id'] = create(resource).id
                  end
                  if params[:parent].present?
                    parent_resource = params.delete(:parent)
                    params["#{parent_resource}_id"] = create(parent_resource).id
                  end
                  begin
                    get(action, params:)
                  rescue AbstractController::ActionNotFound
                    flunk "Testing for an unknown action: #{action}"
                  end
                end
                should redirect_to('login page') { login_path }
              end
            end
          end
        end
        # rubocop:enable Metrics/PerceivedComplexity, Metrics/MethodLength, Metrics/BlockLength
      end
    end
  end
end
