module Submission::WorkflowsHelper
  def dynamic_link_to(summary_item)
    object = summary_item.object
    if object.instance_of?(Submission)
      return link_to("Submission #{object.id}", study_workflow_submission_path(object.study, object.workflow, object))
    elsif object.instance_of?(Asset)
        return link_to("#{object.label.capitalize} #{object.name}", asset_path(object))
    elsif object.instance_of?(Request)
        return link_to("Request #{object.id}", request_path(object))
    else
      return 'No link available'
    end
  end
end
