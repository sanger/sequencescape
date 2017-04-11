# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require File.join(File.dirname(__FILE__), 'sanger_macros', 'resource_test')

module Sanger
  module Testing
    module Controller
      module Macros
        def should_have_instance_methods(*methods)
          dt = described_type
          should "have instance methods #{methods.join(',')}" do
            methods.each do |method|
              assert dt.instance_methods.include?(method), "Missing instance methods #{method}"
            end
          end
        end

        def should_have_successful_submission
          # FIXME: routing doesnt work property
          # should redirect_to("study workflow submission page"){ study_workflow_submission_url(@study, @workflow, @submission) }
          should 'have a successful submission' do
            assert_not_nil @controller.session.try(:[], :flash).try(:[], :notice).try(:include?, 'Submission successfully created')
            assert_equal @submission_count + 1, Submission.count
          end
        end

        def should_require_login(*actions)
          params = actions.pop if actions.last.is_a?(Hash)
          actions << :index if actions.empty?
          actions.each do |action|
            context action.to_s do
              context 'when logged in' do
                setup do
                  session[:user] = create(:user)
                  begin
                    get action, params
                  rescue AbstractController::ActionNotFound
                     flunk "Testing for an unknown action: #{action}"
                  rescue ActiveRecord::RecordNotFound
                    assert true
                  rescue ActionView::MissingTemplate
                    flunk "Missing template for #{action} action"
                  rescue
                    # Assume any other problem is due to the controller not handling things
                    assert true
                  end
                end
                should 'not redirect' do
                  assert !(300..307).to_a.include?(@response.code)
                end
              end
              context 'when not logged in' do
                setup do
                  session[:user] = nil

                  begin
                    get action, params
                  rescue AbstractController::ActionNotFound
                    flunk "Testing for an unknown action: #{action}"
                  end
                end
                should redirect_to('login page') { login_path }
              end
            end
          end
        end
      end
    end
  end
end
