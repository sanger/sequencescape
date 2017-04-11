# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2007-2011,2012,2015 Genome Research Ltd.

class CherrypickGroupBySubmissionTask < Task
  include Cherrypick::Task::PickHelpers
  include Tasks::PlatePurposeBehavior
  include Request::GroupingHelpers

  class CherrypickGroupBySubmissionData < Task::RenderElement
    alias_attribute :well, :asset

    def initialize(request)
      super(request)
    end
  end

  def create_render_element(request)
    request.asset && CherrypickGroupBySubmissionData.new(request)
  end

  def partial
    'cherrypick_group_by_submission_batches'
  end

  def render_task(workflow, params)
    super
    workflow.render_cherrypick_group_by_submission_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_cherrypick_group_by_submission_task(self, params)
  end

  def valid_params?(options = {})
    cherrypick_action = options[:cherrypick][:action]
    param_checker_for_pick = "valid_params_for_#{cherrypick_action}_pick?"
    respond_to?(param_checker_for_pick, true) ? send("valid_params_for_#{cherrypick_action}_pick?", options[cherrypick_action]) : false
  end
end
