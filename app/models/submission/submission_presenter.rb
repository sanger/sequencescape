#This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
#Please refer to the LICENSE and README files for information on licensing and authorship of this file.
#Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.
class Submission::SubmissionPresenter < Submission::PresenterSkeleton
  write_inheritable_attribute :attributes, [ :id ]

  def submission
    @submission ||= Submission.find(id)
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

