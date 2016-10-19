#This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2007-2011,2015 Genome Research Ltd.

class Projects::Workflows::ItemsController < ApplicationController

  def index
    @workflow = Submission::Workflow.find(params[:workflow_id])
    @project  = Project.find(params[:project_id])

    submissions = @project.submissions.select { |s| s.workflow == @workflow }
    @items = submissions.map { |s| s.items }.flatten.uniq

    respond_to do |format|
      format.html
      format.xml { render :xml => @items.to_xml }
    end
  end

end
