# This file is part of SEQUENCESCAPE; it is distributed under the terms of
# GNU General Public License version 1 or later;
# Please refer to the LICENSE and README files for information on licensing and
# authorship of this file.
# Copyright (C) 2012,2013,2014,2015 Genome Research Ltd.

class Submission::SubmissionPresenter < Submission::PresenterSkeleton
  self.attributes = [:id]

  def submission
    @submission ||= Submission.find(id)
  end

  delegate :priority, to: :submission

  delegate :template_name, to: :order

  def order
    submission.orders.first
  end

  # Deleting a Submission should also delete all associated Orders.
  def destroy
    submission.orders.destroy_all
    submission.destroy
  end
end
