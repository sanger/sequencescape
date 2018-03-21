# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2015 Genome Research Ltd.

require 'test_helper'

module Studies
  class CommentsControllerTest < ActionController::TestCase
    context 'Studies controller' do
      setup do
        @controller = Studies::CommentsController.new
        @request    = ActionController::TestRequest.create(@controller)
      end

      should_require_login(:index, resource: 'comment', parent: 'study')

      resource_test('comment', actions: ['index'], ignore_actions: %w(new edit update show destroy create), formats: ['html'], parent: 'study', other_actions: ['add'])
    end
  end
end
