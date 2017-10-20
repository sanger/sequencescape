# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015,2016 Genome Research Ltd.

require 'test_helper'
require 'studies_controller'

class StudiesControllerTest < ActionController::TestCase
  context 'StudiesController' do
    setup do
      @controller = StudiesController.new
      @request    = ActionController::TestRequest.create(@controller)
    end

    resource_test(
      'study',         defaults: { name: 'study name' },
                       user: :admin,
                       other_actions: ['properties', 'study_status'],
                       ignore_actions: %w(show create update destroy),
                       formats: ['xml']
    )
  end
end
