#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011 Genome Research Ltd.
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
