# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

require 'test_helper'

module Samples
  class CommentsControllerTest < ActionController::TestCase
    context 'Samples#Comments controller' do
      setup do
        @controller = Samples::CommentsController.new
        @request    = ActionController::TestRequest.create(@controller)
      end

      should_require_login(:index, resource: 'comment', parent: 'sample')

      resource_test('comment', actions: ['index'], ignore_actions: %w(destroy create edit new show update), formats: ['html'], parent: 'sample')
    end
  end
end
