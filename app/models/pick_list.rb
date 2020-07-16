# A pick list is a lightweight wrapper to provide a simplified interface
# for automatically generating {Batch batches} for the {CherrypickPipeline}
# It is intended to isolate external applications from the implimentation
# and to provide an interface for eventually building a simplified means
# or generating cherrypicks
class PickList < ApplicationRecord
  # TODO: This will likely go through a refactor
  SUBMISSION_TEMPLATE_NAME = 'Cherrypick'.freeze
  # PickLists are currently a wrapper for submissions, and batches. In future
  # it would be nice if we could make them more lightweight, and the cherrypicking
  # interface would use them directly.
  belongs_to :submission, optional: false, autosave: true
  enum state: { pending: 0, built: 1 }

  # Asynchronous indicates whether the submission should be built asynchronously
  # via the delayed job, or synchronously.
  attribute :asynchronous, :boolean, default: true

  # We over-ride the setter
  def receptacles=(receptacles)
    # order.assets = receptacles
  end

  private

  def order
    submission.orders.first
  end

  # Returns the submission associated with the pick-list.
  # Its listed as a private method, as it is intended as an implimentation
  # detail, and I'm hoping that we'll be able to remove the need for it.
  def submission
    super || self.submission = create_submission
  end

  def create_submission
    submission_template.create_with_submission!.submission
  end

  def submission_template
    SubmissionTemplate.find_by!(name: SUBMISSION_TEMPLATE_NAME)
  end
end
