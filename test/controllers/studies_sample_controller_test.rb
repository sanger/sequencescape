# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'
require 'studies/workflows_controller'

module Studies
  class SamplesControllerTest < ActionController::TestCase
    context 'Studies controller' do
      setup do
        @controller = Studies::SamplesController.new
        @request    = ActionController::TestRequest.create(@controller)

        @user = create :user
        session[:user] = @user.id
        @workflow = create :submission_workflow
      end

      should_require_login(:index, resource: 'sample', parent: 'study')

      resource_test('sample', parent: 'study', actions: ['index'], ignore_actions: ['show'], formats: ['html'])
    end
  end
end
