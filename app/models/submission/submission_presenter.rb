# frozen_string_literal: true
class Submission::SubmissionPresenter < Submission::PresenterSkeleton # rubocop:todo Style/Documentation
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
