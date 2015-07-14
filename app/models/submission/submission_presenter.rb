#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
class Submission::SubmissionPresenter < Submission::PresenterSkeleton
  write_inheritable_attribute :attributes, [ :id ]

  def submission
    @submission ||= Submission.find(id)
  end

  def order_studies
    if order.study
      yield(order.study.name, order.study)
    else # Cross study
      Study.in_assets(order.all_assets).each do |study|
        yield(study.name,study)
      end
    end
  end

  def order_projects
    if order.project
      yield(order.project.name, order.project)
    else # Cross Project
      Project.in_assets(order.all_assets).each do |project|
        yield(project.name,project)
      end
    end
  end

  def priority
    submission.priority
  end

  def template_name
    submission.orders.first.template_name
  end

  def order
    submission.orders.first
  end

  # Deleting a Submission should also delete all associated Orders.
  def destroy
    submission.orders.destroy_all
    submission.destroy
  end

end

