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
    "cherrypick_group_by_submission_batches"
  end

  def render_task(workflow, params)
    super
    workflow.render_cherrypick_group_by_submission_task(self, params)
  end

  def do_task(workflow, params)
    workflow.do_cherrypick_group_by_submission_task(self, params)
  end

  def valid_params?(options = {})
    param_checker_for_pick = "valid_params_for_#{options[:cherrypick][:action]}_pick?"
    respond_to?(param_checker_for_pick, true) ? send("valid_params_for_#{options[:cherrypick][:action]}_pick?", options) : false
  end
end
